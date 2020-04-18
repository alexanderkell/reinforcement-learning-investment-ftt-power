from __future__ import absolute_import
from __future__ import division
from __future__ import print_function
"""Example of running a policy server. Copy this file for your use case.
To try this out, in two separate shells run:
    $ python cartpole_server.py
    $ python cartpole_client.py
"""

from ray.rllib.agents.pg import PGTrainer
from ray.rllib.env.external_multi_agent_env import ExternalMultiAgentEnv
from ray.rllib.utils.policy_server import PolicyServer

import sys
sys.path.append("/Users/b1017579/Documents/PhD/Projects/12-Reinforcement-Learning/Examples/")


from ray.tune import register_env, grid_search
from ray.tune.logger import pretty_print


import gym
from gym import error, spaces, utils
from gym.utils import seeding

from gym.spaces import Tuple, Box
import numpy as np
import ray
from ray import tune
from ray.tune import register_env, grid_search
from ray.rllib.env.multi_agent_env import MultiAgentEnv
from ray.tune import register_env, grid_search
import collections
from ray.tune.logger import pretty_print

from ray.rllib.agents.dqn.dqn import DQNTrainer
from ray.rllib.agents.dqn.dqn_policy import DQNTFPolicy
from ray.rllib.agents.ppo.ppo import PPOTrainer
from ray.rllib.agents.ppo.ppo_policy import PPOTFPolicy
from ray.rllib.tests.test_multi_agent_env import MultiCartpole

import ray
import ray.rllib.agents.ppo as ppo



SERVER_ADDRESS = "localhost"
SERVER_PORT = 9900
CHECKPOINT_FILE = "last_checkpoint.out"


class FooEnv(MultiAgentEnv):
    action_space = spaces.Box(low=-1, high=1000, shape=(1,), dtype=np.float)
    observation_space = spaces.Box(low=-1000, high=1000, shape=(1,), dtype=np.float)

    def __init__(self, number_of_agents=10):
        self.number_of_agents = number_of_agents

        print("Initting FooEnv")
        self.number_of_steps = 0

    def step(self, action_dict):
        self.number_of_steps += 1
        reward_dict = dict.fromkeys(action_dict)
        sorted_x = sorted(action_dict.items(), key=lambda kv: kv[1])
        sorted_dict = collections.OrderedDict(sorted_x)
        obs = {}
        total_capacity_required = 50
        for key, action in sorted_dict.items():
            if total_capacity_required > 0:
                reward_dict[key] = action[0]
                obs[key] = np.array(action[0]).reshape(1,)
            else:
                reward_dict[key] = np.array(-10)
                # obs[key] = [np.array(0)]
                obs[key] = np.array(0).reshape(1,)

            total_capacity_required -= 10
        if self.number_of_steps < 50:
            dones = {"__all__": False}
        else:
            dones = {"__all__": True}
        infos = {}
        return obs, reward_dict, dones, infos

    def reset(self):
        self.number_of_steps = 0
        # return {"agent_{}".format(i+1): [np.array(0)] for i, _ in enumerate(range(self.number_of_agents))}
        return {"agent_{}".format(i+1): np.array(0).reshape(1,) for i, _ in enumerate(range(self.number_of_agents))}
        # return {"agent_{}".format(i+1): 0 for i, _ in enumerate(range(self.number_of_agents))}




class MarketServing(ExternalMultiAgentEnv):

    def __init__(self):
        ExternalMultiAgentEnv.__init__(
            self, FooEnv.action_space,
            FooEnv.observation_space)

    def run(self):
        print("Starting policy server at {}:{}".format(SERVER_ADDRESS,
                                                       SERVER_PORT))
        server = PolicyServer(self, SERVER_ADDRESS, SERVER_PORT)
        server.serve_forever()


if __name__ == "__main__":

    # grouping = {
    #     "group_1":
    #         ['agent_1', "agent_2", 'agent_3', 'agent_4', 'agent_5', 'agent_6', 'agent_7', 'agent_8'],
    #     "group_2":
    #         ['agent_9', 'agent_10']
    # }

    # obs_space_1 = Tuple([FooEnv.observation_space]*10)
    # action_space_1 = Tuple([FooEnv.action_space]*10)
    # obs_space_2 = Tuple([FooEnv.observation_space]*2)
    # action_space_2 = Tuple([FooEnv.action_space]*2)

    ray.init()
    register_env("srv", lambda _: MarketServing())

    # We use DQN since it supports off-policy actions, but you can choose and
    # configure any agent.
    dqn = PGTrainer(
        env="srv",
        config={
            # Use a single process to avoid needing to set up a load balancer
            "num_workers": 0,
            # "multiagent": {
            #     # "grouping":
            #     #     grouping,
            #     "policies": {
            #         # the first tuple value is None -> uses default policy
            #         "function_1": (None, obs_space_1, action_space_1, {}),
            #         "function_2": (None, obs_space_2, action_space_2, {})
            #     },
            #     "policy_mapping_fn":
            #         # tune.function(lambda agent_id: "agent_{}".format(agent_id+1)),
            #         tune.function(lambda agent_id: "function_1" if agent_id == "group_1" else "function_2"),
            # },
        })

    # Attempt to restore from checkpoint if possible.
    # if os.path.exists(CHECKPOINT_FILE):
    #     checkpoint_path = open(CHECKPOINT_FILE).read()
    #     print("Restoring from checkpoint path", checkpoint_path)
    #     dqn.restore(checkpoint_path)

    # Serving and training loop
    while True:
        print(pretty_print(dqn.train()))
        checkpoint_path = dqn.save()
        print("Last checkpoint", checkpoint_path)
        with open(CHECKPOINT_FILE, "w") as f:
            f.write(checkpoint_path)


