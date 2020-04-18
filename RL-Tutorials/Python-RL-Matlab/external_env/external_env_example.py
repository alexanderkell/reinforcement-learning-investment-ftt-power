from ray.rllib.env.external_env import ExternalEnv
from ray.rllib.env.base_env import BaseEnv
from gym.spaces import Tuple, Box
from ray.tune.registry import register_env
from ray.rllib.agents.dqn import DQNTrainer
from ray.rllib.agents.ppo import PPOTrainer
import numpy as np

import gym, ray, ray.tune
from ray.rllib.utils.policy_server import PolicyServer

import ray
from ray import tune
from ray.rllib.utils import try_import_tf
from ray.tune import grid_search

"""
File name: external_env_example
Date created: 18/04/2020
Feature: #Enter feature description here
"""

__author__ = "Alexander Kell"
__copyright__ = "Copyright 2018, Alexander Kell"
__license__ = "MIT"
__email__ = "alexander@kell.es"




# client_rl = ExternalEnv(action_space=action_space, observation_space=observation_space)
#
# episode_id = client_rl.start_episode()
#
# client_rl.get_action(episode_id=episode_id, observation=None)
#
# client_rl.log_returns(episode_id=episode_id, reward=None)
#
# client_rl.end_episode(episode_id=episode_id, observation=None)

SERVER_ADDRESS = "localhost"
SERVER_PORT = 9900
CHECKPOINT_FILE = "last_checkpoint.out"


class AdderServing(ExternalEnv):

    def __init__(self, action_space, observation_space):
        ExternalEnv.__init__(self, action_space, observation_space)


    def run(self):
        print("Starting policy server at {}:{}".format(SERVER_ADDRESS, SERVER_PORT))
        server = PolicyServer(self, SERVER_ADDRESS, SERVER_PORT)
        server.serve_forever()

class AdderEnvironment(gym.Env):

    def __init__(self, action_space, observation_space):
        self.action_space = action_space
        self.observation_space = observation_space

    def reset(self):
        # return np.array(0).reshape(1,)
        return np.array([0]).reshape(1,)

    def step(self, action):
        reward = action[0] + action[1]
        # print(reward)
        obs = reward
        if reward >= 1980:
            done = True
        else:
            done = False

        return np.array([obs, action[0], action[2]]).reshape(1,), reward, done, {}


# Run RL algorithm
# ray.init()



# client_environment = AdderEnvironment(action_space=action_space, observation_space=observation_space)

# register_env("my_env", lambda _: client_environment)

if __name__ == "__main__":
    action_space = Box(low=-1000, high=1000, shape=(2,), dtype=np.float)
    observation_space = Box(low=-2000, high=2000, shape=(3,), dtype=np.float)

    # Can also register the env creator function explicitly with:
    # register_env("corridor", lambda config: SimpleCorridor(config))
    ray.init(object_store_memory=5000000000)
    # ModelCatalog.register_custom_model("my_model", CustomModel)
    client_environment = AdderEnvironment(action_space=action_space, observation_space=observation_space)

    register_env("my_env", lambda _: client_environment)

    tune.run(
        "PPO",
        stop={
            "timesteps_total": 100000,
        },
        config={
            "env": 'my_env',  # or "corridor" if registered above
            "vf_share_layers": True,
            # "lr": grid_search([1e-2, 1e-4, 1e-6]),  # try different lrs
            "lr": grid_search([1e-2]),  # try different lrs
            "num_workers": 1,  # parallelism
        },
    )

# trainer = PPOTrainer(env="my_env")
# while True:
#     print(trainer.train())
