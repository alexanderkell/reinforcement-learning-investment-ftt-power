#!/usr/bin/env python
"""Example of running a policy server. Copy this file for your use case.
To try this out, in two separate shells run:
    $ python cartpole_server.py
    $ python cartpole_client.py --inference-mode=local|remote
"""

import argparse
import os

import ray
from ray.rllib.agents.dqn import DQNTrainer
from ray.rllib.agents.ppo import PPOTrainer
from ray.rllib.agents.ddpg import DDPGTrainer
from ray.rllib.env.policy_server_input import PolicyServerInput
from ray.tune.logger import pretty_print
from gym.spaces import Box, Discrete, MultiDiscrete
from ray.rllib.utils.policy_server import PolicyServer

from ray.tune.registry import register_env
from ray.rllib.env.external_env import ExternalEnv
import gym
import numpy as np

SERVER_ADDRESS = "localhost"
SERVER_PORT = 9900
CHECKPOINT_FILE = "last_checkpoint_{}.out"

parser = argparse.ArgumentParser()
parser.add_argument("--run", type=str, default="DQN")

class AdderServing(gym.Env):

    def __init__(self, action_space, observation_space):
        ExternalEnv.__init__(self, action_space, observation_space)


    def run(self):
        print("Starting policy server at {}:{}".format(SERVER_ADDRESS, SERVER_PORT))
        server = PolicyServer(self, SERVER_ADDRESS, SERVER_PORT)
        server.serve_forever()


if __name__ == "__main__":
    # SERVER_ADDRESS = "localhost"
    SERVER_ADDRESS = "127.0.0.1"
    SERVER_PORT = 9912
    args = parser.parse_args()
    args.run = "PPO"
    ray.init()
    # action_space = MultiDiscrete(50)
    action_space = Box(low=0.2, high=0.7, shape=(326,), dtype=np.float)
    observation_space = Box(low=0, high=99999999, shape=(11,), dtype=np.float)
    register_env("srv", lambda config: AdderServing(action_space, observation_space))
    connector_config = {
        # Use the connector server to generate experiences.
        "input": (
            lambda ioctx: PolicyServerInput(ioctx, SERVER_ADDRESS, SERVER_PORT)
        ),
        # Use a single worker process to run the server.
        "num_workers": 0,
        # Disable OPE, since the rollouts are coming from online clients.
        "input_evaluation": [],
    }

    # if args.run == "DDPG":
        # Example of using PPO (does NOT support off-policy actions).
    trainer = DDPGTrainer(
        env='srv',
        config=dict(
            connector_config, **{
                "sample_batch_size": 10000,
                "train_batch_size": 40000,
            }))
    # elif args.run == "DQN":
    #     # Example of using DQN (supports off-policy actions).
    #     trainer = DQNTrainer(
    #         env='srv',
    #         config=dict(
    #             connector_config, **{
    #                 "exploration_config": {
    #                     "type": "EpsilonGreedy",
    #                     "initial_epsilon": 1.0,
    #                     "final_epsilon": 0.02,
    #                     "epsilon_timesteps": 1000,
    #                 },
    #                 "learning_starts": 100,
    #                 "timesteps_per_iteration": 200,
    #                 "log_level": "INFO",
    #             }))
    # elif args.run == "PPO":
    #     # Example of using PPO (does NOT support off-policy actions).
    #     trainer = PPOTrainer(
    #         env='srv',
    #         config=dict(
    #             connector_config, **{
    #                 "sample_batch_size": 1000,
    #                 "train_batch_size": 4000,
    #             }))
    # else:
    #     raise ValueError("--run must be DQN or PPO")

    # checkpoint_path = CHECKPOINT_FILE.format(args.run)
    # checkpoint_path = 'RL_Checkpoints/21-May-2020/checkpoint-460.pickle'
    # checkpoint_path_meta = "RL_Checkpoints/21-May-2020/checkpoint-460"


    # checkpoint_path = "../../../../../ray_results/DDPG_srv_2020-05-21_18-26-289tv41p5j/checkpoint_458/checkpoint-458.pickle"
    # checkpoint_path_meta = "../../../../../ray_results/DDPG_srv_2020-05-21_18-26-289tv41p5j/checkpoint_458/checkpoint-458"
    # Attempt to restore from checkpoint if possible.
    checkpoint_path = "start_afresh"
    import pickle
    if os.path.exists(checkpoint_path):
        # checkpoint_path = open(checkpoint_path).read()
        # print("Restoring from checkpoint path", checkpoint_path)
        # trainer.restore(checkpoint_path)
        # checkpoint_path = open(checkpoint_path).read()
        checkpoint_path = pickle.load(open(checkpoint_path, "rb"))
        # print("Restoring from checkpoint path", checkpoint_path)
        print("Trying to restore")
        trainer.restore(checkpoint_path_meta)
        print("Restored")
        # open("../../data/raw/pickled_data/{}_restuarants_data.p".format(self.postcode,),



    # Serving and training loop
    while True:
        print(pretty_print(trainer.train()))
        checkpoint = trainer.save()
        checkpoint_path_save = CHECKPOINT_FILE.format(args.run)
        print("Last checkpoint", checkpoint)
        with open(checkpoint_path_save, "w") as f:
            f.write(checkpoint_path_save)
