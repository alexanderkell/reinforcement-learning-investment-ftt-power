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


if __name__ == "__main__":

    ray.init()
    # obs_space = FooEnv.observation_space
    # action_space = FooEnv.action_space

    obs_space_1 = Tuple([FooEnv.observation_space]*10)
    action_space_1 = Tuple([FooEnv.action_space]*10)
    obs_space_2 = Tuple([FooEnv.observation_space]*2)
    action_space_2 = Tuple([FooEnv.action_space]*2)

    # grouping = {
    #     "group_1": {
    #         "members": ['agent_1', "agent_2", 'agent_3', 'agent_4', 'agent_5', 'agent_6', 'agent_7', 'agent_8'],
    #         "obs_space": obs_space_1,
    #         "action_space": action_space_1
    #     },
    #     "group_2": {
    #         "members": ['agent_9', 'agent_10'],
    #         "obs_space": obs_space_2,
    #         "action_space": action_space_2
    #     }
    # }
    grouping = {
        "group_1":
            ['agent_1', "agent_2", 'agent_3', 'agent_4', 'agent_5', 'agent_6', 'agent_7', 'agent_8', 'agent_9', 'agent_10'],
        # "group_2":
            # ['agent_9', 'agent_10']
        
    }

    

    register_env("market23_env", lambda config: FooEnv().with_agent_groups(grouping))
    # register_env("market23_env", lambda config: FooEnv())

    tune.run(
        "PPO",
        stop={
            "timesteps_total": 1000000,
        },
        config={
            "env": "market23_env",  # or "corridor" if registered above
            # "lr": grid_search([1e-2, 1e-4, 1e-6]),  # try different lrs
            "num_workers": 3,  # parallelism
            "multiagent": {
                # "grouping":
                #     grouping,
                "policies": {
                    # the first tuple value is None -> uses default policy
                    "function_1": (None, obs_space_1, action_space_1, {}),
                    "function_2": (None, obs_space_2, action_space_2, {})
                },
                "policy_mapping_fn":
                    # tune.function(lambda agent_id: "agent_{}".format(agent_id+1)),
                    tune.function(lambda agent_id: "function_1" if agent_id == "group_1" else "function_2"),
            },
            "log_level": "DEBUG"
        }
    )

    # ppo_trainer = PPOTrainer(
    #     env="market23_env",
    #     config={
    #         "multiagent": {
    #             "policies": policies,
    #             "policy_mapping_fn": policy_mapping_fn,
    #             "policies_to_train": ["agent_1", "agent_2"],
    #         },
    #         # disable filters, otherwise we would need to synchronize those
    #         # as well to the DQN agent
    #         # "observation_filter": "NoFilter",
    #     })

    # for i in range(100):
    #     print(pretty_print(ppo_trainer.train()))

    # config = {
    #     "num_gpus": 0,
    #     "num_workers": 2,
    #     "optimizer": {
    #         "num_replay_buffer_shards": 1,
    #     },
    #     "min_iter_time_s": 3,
    #     "buffer_size": 1000,
    #     "learning_starts": 1000,
    #     "train_batch_size": 128,
    #     "sample_batch_size": 32,
    #     "target_network_update_freq": 500,
    #     "timesteps_per_iteration": 1000,
    # }

    




    # trainer = ppo.PPOAgent(env="market23_env")
    # while True:
    #     print("training")
    #     print(trainer.train())





    # group = True

    # ray.init()
    # tune.run(
    #     "PPO",
    #     stop={
    #         "timesteps_total": 200000,
    #     },
    #     config=dict(config, **{
    #         "env": "market23_env",
    #     }),
    # )