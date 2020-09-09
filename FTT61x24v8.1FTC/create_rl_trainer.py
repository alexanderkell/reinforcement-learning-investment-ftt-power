import matlab.engine
import argparse
import os

from multiprocessing import Process
from subprocess import Popen
import ray
from ray.rllib.agents.dqn import DQNTrainer
from ray.rllib.agents.ppo import PPOTrainer
from ray.rllib.agents.ddpg import DDPGTrainer
from ray.rllib.env.policy_server_input import PolicyServerInput
from ray.tune.logger import pretty_print
from gym.spaces import Box, Discrete, MultiDiscrete
from ray.rllib.utils.policy_server import PolicyServer

from ray.tune.registry import register_env
import ray.tune as tune
from ray.rllib.env.external_env import ExternalEnv
import gym
import numpy as np
parser = argparse.ArgumentParser()


print("creating RL Trainer")

SERVER_ADDRESS = "127.0.0.1"
SERVER_PORT = 9912
args = parser.parse_args()

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


trainer = DDPGTrainer(
    env='srv',
    config=dict(
        connector_config, **{
            "sample_batch_size": 10000,
            "train_batch_size": 40000,
        }))

while True:
    print(pretty_print(trainer.train()))