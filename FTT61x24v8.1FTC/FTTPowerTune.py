#!/usr/bin/env python
"""Example of running a policy server. Copy this file for your use case.
To try this out, in two separate shells run:
    $ python cartpole_server.py
    $ python cartpole_client.py --inference-mode=local|remote
"""

import matlab.engine
import argparse
import os
import time
from multiprocessing import Process
from subprocess import Popen
import ray
from ray.rllib.agents.dqn import DQNTrainer
from ray.rllib.agents.ppo import PPOTrainer
from ray.rllib.agents.ddpg import DDPGTrainer
# from ray.rllib.env.policy_server_input import PolicyServerInput
from ray.tune.logger import pretty_print
from gym.spaces import Box, Discrete, MultiDiscrete
from ray.rllib.env import PolicyServerInput 
from ray.rllib.agents.trainer_template import build_trainer

from ray.tune.registry import register_env
# import ray.tune as tune
from ray.rllib.env.external_env import ExternalEnv
import gym
import numpy as np

from io import StringIO
import logging

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
        server = PolicyServerInput(self, SERVER_ADDRESS, SERVER_PORT)
        server.serve_forever()

@ray.remote
def run_ftt_power(port, actor_layers, critic_layers, eng):
    actor_layers = '-'.join(str(e) for e in actor_layers)
    critic_layers = '-'.join(str(e) for e in critic_layers)

    print("Starting FTT Power")
    # eng = matlab.engine.start_matlab()
    # eng = matlab.engine.connect_matlab()
    # eng.Run_FTT_Power(port, actor_layers, critic_layers, eng, nargout=1)
    with matlab.engine.start_matlab() as eng:
        print("Running FTT Power")
        time.sleep(5)
#         eng.Run_FTT_Power(port, actor_layers, critic_layers, nargout=1)
        out = StringIO()
        err = StringIO()
        retvals = eng.Run_FTT_Power(port, actor_layers, critic_layers, nargout=1,stdout=out,stderr=err)
        outstring = out.getvalue()
        errstring = err.getvalue()
        logging.debug('ml output:'+str(outstring)+'\n')
        logging.debug('ml err output:'+str(errstring)+'\n')
    # return None

@ray.remote
def create_rl_trainer(port, actor_hidden, critic_hidden):
    SERVER_ADDRESS = "127.0.0.1"
    SERVER_PORT = port
    # args = parser.parse_args()

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
        # name="actor-{}_critic-{}".format(actor_hidden, critic_hidden),
        config=dict(
            connector_config, **{
                # "sample_batch_size": 10000,
                "train_batch_size": 40000,
                "actor_hiddens": actor_hidden,
                'critic_hiddens': critic_hidden
            }))

    # for _ in range(100):
    while True:
        print(pretty_print(trainer.train()))

    # return None

@ray.remote
def run_model(port, actor_layers, critic_layers, eng):
    print("running on port: {}".format(port))

    ray.get([create_rl_trainer.remote(port, actor_layers, critic_layers), run_ftt_power.remote(port, actor_layers, critic_layers, eng)])
    # return None


if __name__ == "__main__":
    # SERVER_ADDRESS = "localhost"
    SERVER_ADDRESS = "127.0.0.1"
    SERVER_PORT = 9912
    # args = parser.parse_args()
    # args.run = "PPO"
    # ray.init(num_cpus=7)
    ray.init()
    # action_space = MultiDiscrete(50)
    action_space = Box(low=0, high=0.1, shape=(2,), dtype=np.float)
    observation_space = Box(low=0, high=99999999, shape=(11,), dtype=np.float)
    register_env("srv", lambda config: AdderServing(action_space, observation_space))

    # os.chdir("/Users/alexanderkell/Documents/PhD/Projects/17-ftt-power-reinforcement/FTT61x24v8.1FTC/")
    os.chdir("/home/ps/ce-fs2/akell/PhD/ftt-power/reinforcement-learning-investment-ftt-power/FTT61x24v8.1FTC/")
    # os.chdir("/home/alexander/Documents/reinforcement-learning-investment-ftt-power/FTT61x24v8.1FTC")
    # eng = matlab.engine.start_matlab()
    # print("Matlab started")
    eng = 1
    actor_hidden = [
        # [300, 300],
        # [400, 300],
        # [300, 400],
        [400, 400],
        # [300, 500],
        # [400, 500],
        # [300, 300, 300],
        # [400, 400, 400],
    ]

    critic_hidden = [
        # [300, 300],
        # [400, 300],
        # [300, 400],
        [400, 400],
        # [300, 500],
        # [400, 500],
        # [300, 300, 300],
        # [400, 400, 400],
    ]

    results = []
    for port, actor_layers, critic_layers in zip(range(9940, 9940+len(actor_hidden)), actor_hidden, critic_hidden):
        # ray.get([create_rl_trainer.remote(9912, actor_layers, critic_layers), run_ftt_power.remote(9912, actor_layers, critic_layers)])
        result = run_model.remote(port, actor_layers, critic_layers, eng)
        results.append(result)
    ray.get(results)

