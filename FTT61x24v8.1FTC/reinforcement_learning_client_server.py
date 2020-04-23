from ray.rllib.env.external_env import ExternalEnv
from ray.rllib.env.base_env import BaseEnv
from gym.spaces import Tuple, Box, Discrete
from ray.tune.registry import register_env
from ray.rllib.agents.dqn import DQNTrainer
from ray.rllib.agents.ppo import PPOTrainer
import numpy as np

import gym, ray, ray.tune
from ray.rllib.utils.policy_server import PolicyServer
from ray.rllib.models import ModelCatalog
import ray
from ray import tune
from ray.rllib.utils import try_import_tf
from ray.tune import grid_search
import matlab.engine


"""
File name: reinforcement_learning_client_server
Date created: 20/04/2020
Feature: #Enter feature description here
"""

__author__ = "Alexander Kell"
__copyright__ = "Copyright 2018, Alexander Kell"
__license__ = "MIT"
__email__ = "alexander@kell.es"


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


class FTTPowerEnvironment(gym.Env):

    def __init__(self, action_space, observation_space):
        self.action_space = action_space
        self.observation_space = observation_space

    def reset(self):
        # return np.array(0).reshape(1,)
        return np.array([0, 0]).reshape(2,)

    def step(self, action):
        # reward = action[0] + action[1]
        reward = action * 2
        # print(reward)
        obs = reward
        if reward >= 50:
            done = True
        else:
            done = False

        # return np.array([obs, action[0], action[1]]).reshape(3,), reward, done, {}
        return np.array([obs, action]).reshape(2,), reward, done, {}


class FTTPowerExternalEnvironment(ExternalEnv):

    def __init__(self, action_space, observation_space):
        super().__init__(action_space, observation_space)

    def run(self):

        # Your loop should continuously:
        while True:
            episode_id = self.start_episode()
            env = AdderEnvironment(self.action_space, self.observation_space)
            observation = env.reset()
            for _ in range(1000):
                action = self.get_action(episode_id, observation)
                observation, reward, done, info = env.step(action)
                self.log_returns(episode_id, reward)
            self.end_episode(episode_id, observation)



# Run RL algorithm
# ray.init()



# client_environment = AdderEnvironment(action_space=action_space, observation_space=observation_space)

# register_env("my_env", lambda _: client_environment)

if __name__ == "__main__":
    eng = matlab.engine.start_matlab()
    print("Running FTT:Power   ")
    result = eng.Run_FTT_Power("action", 61.0, 24.0)
    print(result)
#     # action_space = Box(low=-1000, high=1000, shape=(2,), dtype=np.float)
#     action_space = Discrete(100)
#
#     observation_space = Box(low=-2000, high=2000, shape=(2,), dtype=np.float)
#
#     # Can also register the env creator function explicitly with:
#     # register_env("corridor", lambda config: SimpleCorridor(config))
#     ray.init(object_store_memory=5000000000)
#     # client_environment = AdderEnvironment(action_space=action_space, observation_space=observation_space)
#     client_environment = AdderExternalEnvironment(action_space=action_space, observation_space=observation_space)
#
#     register_env("my_env", lambda _: AdderExternalEnvironment(action_space=action_space, observation_space=observation_space))
#     # ModelCatalog.register_custom_model("my_model", client_environment)
#
#     tune.run(
#         "DQN",
#         stop={
#             "timesteps_total": 10000000,
#         },
#         config={
#             "env": 'my_env',  # or "corridor" if registered above
#             # "vf_share_layers": True,
#             # 'vf_clip_param': 1000000,
#             # "lr": grid_search([1e-2, 1e-4, 1e-6]),  # try different lrs
#             "lr": grid_search([1e-2]),  # try different lrs
#             "num_workers": 1,  # parallelism
#         },
#     )
#
# # trainer = PPOTrainer(env="my_env")
# # while True:
# #     print(trainer.train())
