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
from ray.rllib.env.policy_server_input import PolicyServerInput
from ray.tune.logger import pretty_print
from gym.spaces import Box, Discrete, MultiDiscrete
from ray.rllib.utils.policy_server import PolicyServer

from ray.tune.registry import register_env
import ray.tune as tune
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

@ray.remote
def run_ftt_power(port):
    os.chdir("/Users/alexanderkell/Documents/PhD/Projects/17-ftt-power-reinforcement/FTT61x24v8.1FTC")
    eng = matlab.engine.start_matlab()
    time.sleep(10)
    eng.Run_FTT_Power(port)

    return None

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
        config=dict(
            connector_config, **{
                "sample_batch_size": 10000,
                "train_batch_size": 40000,
                "actor_hiddens": actor_hidden,
                'critic_hiddens': critic_hidden
            }))

    for _ in range(10):
        print(pretty_print(trainer.train()))

    return None


if __name__ == "__main__":
    # SERVER_ADDRESS = "localhost"
    SERVER_ADDRESS = "127.0.0.1"
    SERVER_PORT = 9912
    args = parser.parse_args()
    args.run = "PPO"
    ray.init()
    # action_space = MultiDiscrete(50)
    action_space = Box(low=0.2, high=0.7, shape=(2,), dtype=np.float)
    observation_space = Box(low=0, high=99999999, shape=(11,), dtype=np.float)
    register_env("srv", lambda config: AdderServing(action_space, observation_space))

    actor_hidden = [
        [300, 300],
        [400, 300],
        [500, 300],
        [300, 400],
        [400, 400],
        [500, 400],
        [300, 500],
        [400, 500],
        [500, 500]
    ]

    critic_hidden = [
        [300, 300],
        [400, 300],
        [500, 300],
        [300, 400],
        [400, 400],
        [500, 400],
        [300, 500],
        [400, 500],
        [500, 500]
    ]

    for actor_layers, critic_layers in zip(actor_hidden, critic_hidden):
        ray.get([create_rl_trainer.remote(9912, actor_layers, critic_layers), run_ftt_power.remote(9912)])


    # eng = matlab.engine.start_matlab()
    # connector_config = {
    #     # Use the connector server to generate experiences.
    #     "input": (
    #         lambda ioctx: PolicyServerInput(ioctx, SERVER_ADDRESS, SERVER_PORT)
    #     ),
    #     # Use a single worker process to run the server.
    #     "num_workers": 0,
    #     # Disable OPE, since the rollouts are coming from online clients.
    #     "input_evaluation": [],
    # }



    # if args.run == "DDPG":
        # Example of using PPO (does NOT support off-policy actions).
    # trainer = DDPGTrainer(
    #     env='srv',
    #     config=dict(
    #         connector_config, **{
    #             "sample_batch_size": 10000,
    #             "train_batch_size": 40000,
    #         }))

    # tune.run("DDPG",
    #          config={'env':'srv', "sample_batch_size": tune.grid_search([100, 10000])})

    # def training_function(x):
        # print(x)
        # trainer = DDPGTrainer(
        #     # env='srv',
        #     config=dict(
        #         **{
        #             "env": 'srv',
        #             "sample_batch_size": x['sample_batch_size'],
        #             "train_batch_size": x['train_batch_size'],
        #         }))
        # p1 = Process(target=run_ftt_power())
        # p1.start()
        # p2 = Process(target=func2)
        # p2.start()
        # return trainer

    sample_batch_size = [10000, 100]
    # for batch_size in sample_batch_size:
        # trainer = DDPGTrainer(
        #     env='srv',
        #     config=dict(
        #         connector_config, **{
        #             "sample_batch_size": 10000,
        #             "train_batch_size": 40000,
        #         }))

        # while True:
        # print(pretty_print(trainer.train()))
            # checkpoint = trainer.save()
            # checkpoint_path_save = CHECKPOINT_FILE.format(args.run)
            # print("Last checkpoint", checkpoint)
            # with open(checkpoint_path_save, "w") as f:
            #     f.write(checkpoint_path_save)



    # Popen(["python3", "/Users/alexanderkell/Documents/PhD/Projects/17-ftt-power-reinforcement/FTT61x24v8.1FTC/create_rl_trainer.py"])
    # Popen(["python3", "/Users/alexanderkell/Documents/PhD/Projects/17-ftt-power-reinforcement/FTT61x24v8.1FTC/run_FTT_power_from_python.py"])



    # tune.register_trainable("trainable_id", lambda x: training_function(x))

    # tune.run("DDPG", "hyper_parameter_tuning",
    #          config = dict(
    #              connector_config, **{
    #                  'env': 'srv',
    #                  "sample_batch_size": tune.grid_search([10000, 40000]),
    #                  "train_batch_size": 40000
    #              }))


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
    # checkpoint_path = "start_afresh"
    # import pickle
    # if os.path.exists(checkpoint_path):
    #     # checkpoint_path = open(checkpoint_path).read()
    #     # print("Restoring from checkpoint path", checkpoint_path)
    #     # trainer.restore(checkpoint_path)
    #     # checkpoint_path = open(checkpoint_path).read()
    #     checkpoint_path = pickle.load(open(checkpoint_path, "rb"))
    #     # print("Restoring from checkpoint path", checkpoint_path)
    #     print("Trying to restore")
    #     trainer.restore(checkpoint_path_meta)
    #     print("Restored")
    #     # open("../../data/raw/pickled_data/{}_restuarants_data.p".format(self.postcode,),
    #
    #
    #
    # # Serving and training loop
    # while True:
    #     print(pretty_print(trainer.train()))
    #     checkpoint = trainer.save()
    #     checkpoint_path_save = CHECKPOINT_FILE.format(args.run)
    #     print("Last checkpoint", checkpoint)
    #     with open(checkpoint_path_save, "w") as f:
    #         f.write(checkpoint_path_save)
