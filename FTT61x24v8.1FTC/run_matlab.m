function result = run_matlab()

    RTLD_NOW=2;
    RTLD_DEEPBIND=8;
    flag=bitor(RTLD_NOW, RTLD_DEEPBIND);
    py.sys.setdlopenflags(int32(flag));

    py.importlib.import_module('ray.rllib.env.policy_client')
    address = strcat('http://127.0.0.1:', num2str(9914));
    client = py.ray.rllib.env.PolicyClient(address);


