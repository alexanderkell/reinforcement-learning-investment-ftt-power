oinfo = rlNumericSpec([4 1]);
oinfo.Name = 'CartPole States';
oinfo.Description = 'x, dx, theta, dtheta';

ActionInfo = rlFiniteSetSpec([-10 10]);
ActionInfo.Name = 'CartPole Action';

env = rlFunctionEnv(oinfo,ActionInfo,'myStepFunction','myResetFunction');
