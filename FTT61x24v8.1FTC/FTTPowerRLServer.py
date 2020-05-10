#!/usr/bin/env python
"""Example of running a policy server. Copy this file for your use case.
To try this out, in two separate shells run:
    $ python cartpole_server.py
    $ python cartpole_client.py --inference-mode=local|remote
"""

import argparse
import os
from ray.rllib.env.external_env import ExternalEnv

import ray
from ray.rllib.agents.dqn import DQNTrainer
from ray.rllib.agents.ppo import PPOTrainer
from ray.rllib.env.policy_server_input import PolicyServerInput
from ray.rllib.utils.policy_server import PolicyServer

from ray.tune.logger import pretty_print
import gym
from gym.spaces import Box, Discrete
import numpy as np
import ray.tune as tune

from ray.tune.registry import register_env

SERVER_ADDRESS = "127.0.0.1"
SERVER_PORT = 9905
CHECKPOINT_FILE = "last_checkpoint_{}.out"

parser = argparse.ArgumentParser()
parser.add_argument("--run", type=str, default="DQN")

class AdderServing(ExternalEnv):

    def __init__(self, action_space, observation_space):
        ExternalEnv.__init__(self, action_space, observation_space)


    def run(self):
        print("Starting policy server at {}:{}".format(SERVER_ADDRESS, SERVER_PORT))
        server = PolicyServer(self, SERVER_ADDRESS, SERVER_PORT+1)
        server.serve_forever()

if __name__ == "__main__":
    args = parser.parse_args()

    ray.init(num_cpus=4)

    # env = FTTPowerEnvironment(1, 2)
    action_space = Discrete(100)
    observation_space = Box(low=-2000, high=2000, shape=(2,), dtype=np.float)

    register_env("srv", lambda config: AdderServing(action_space, observation_space))
    connector_config = {
        # Use the connector server to generate experiences.
        "input": (
            lambda ioctx: PolicyServerInput(ioctx, SERVER_ADDRESS, SERVER_PORT)
        ),
        # Use a single worker process to run the server.
        "num_workers": 2,
        # Disable OPE, since the rollouts are coming from online clients.
        "input_evaluation": [],
    }

    if args.run == "DQN":
        # Example of using DQN (supports off-policy actions).
        trainer = DQNTrainer(
            env="srv",
            config=dict(
                connector_config, **{
                    "exploration_config": {
                        "type": "EpsilonGreedy",
                        "initial_epsilon": 1.0,
                        "final_epsilon": 0.02,
                        "epsilon_timesteps": 1000,
                    },
                    # "learning_starts": 100,
                    # "timesteps_per_iteration": 200,
                    # "log_level": "INFO",
                }))
    elif args.run == "PPO":
        # Example of using PPO (does NOT support off-policy actions).
        trainer = PPOTrainer(
            env="srv",
            config=dict(
                connector_config, **{
                    "sample_batch_size": 1000,
                    "train_batch_size": 4000,
                }))
    else:
        raise ValueError("--run must be DQN or PPO")

    checkpoint_path = CHECKPOINT_FILE.format(args.run)

    # Attempt to restore from checkpoint if possible.
    if os.path.exists(checkpoint_path):
        checkpoint_path = open(checkpoint_path).read()
        print("Restoring from checkpoint path", checkpoint_path)
        trainer.restore(checkpoint_path)

    # Serving and training loop
    while True:
        print(pretty_print(trainer.train()))
        checkpoint = trainer.save()
        print("Last checkpoint", checkpoint)
        with open(checkpoint_path, "w") as f:
            f.write(checkpoint)

    # tune.run_experiments({
    #     "my_experiment": {
    #         # "run": "PG",
    #         "run": "DQN",
    #         "env": "srv",
    #         'checkpoint_at_end': True,
    #         'checkpoint_freq': 500,
    #        # 'restore': '../ray_results/my_experiment/PG_srv_0_2019-11-02_18-13-192rctqjmg/checkpoint_200/checkpoint-200',
    #        #  "config": {
    #             # "num_gpus": 0,
    #             # "num_workers": 1,
    #             # "env": "srv",
    #             # "evaluation_num_episodes": 10,
    #             # # "sgd_stepsize": tune.grid_search([0.01, 0.001, 0.0001])
    #             # "sample_batch_size": 25,
    #             # "train_batch_size": 25,
    #             # "horizon": 25,
    #         # }
    #     }
    # })

