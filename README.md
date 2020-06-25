## Multi-Agent System Simulation Library

### Basic Structure

The base of this simulation tool are the [`BaseAgent`](lib/agents/BaseAgent.m) and [`BaseNetwork`](lib/networks/BaseNetwork.m) classes.
These abstract classes specify the interface that is used to drive the simulation but cannot be used for simulation themselves.
To perform a simulation, you must define a set of classes that inherit from [`BaseAgent`](lib/agents/BaseAgent.m) and [`BaseNetwork`](lib/networks/BaseNetwork.m).

Currently the project contains three such implementations, [`IdealNetwork`](lib/networks/IdealNetwork.m), [`BernoulliNetwork`](lib/networks/BernoulliNetwork.m) and [`SinrNetwork`](lib/networks/sinr/SinrNetwork.m).
The first implements an ideal network without paket loss but a finite transmission range, the second additionally models paket loss using a Bernoulli distribution and the third models the communication channel with the SINR model.
For further information on the third, see [Using the SINR Networking Library](#using-the-sinr-networking-library).

For a high simulation speed, it is important to select the transmission range appropriatly, as interactions between agents should be minimized.
Selecting the range to large can drastically decrease the simulation performance by introducing quadratic scaling in the number of agents.

For the [`BaseAgent`](lib/agents/BaseAgent.m) class, there are no such convenience classes.
Instead, there are several implementations of dynamic systems included in the [`lib/dynamics/`](lib/dynamics) folder that can be used as building blocks for custom agent classes.
Provided are LTI, LPV and general nonlinear dynamics, each in discrete- and continuous-time.
Whenever possible, the agent dynamics should be implemented in discrete-time because the discrete-time evaluation is orders of magnitudes faster.

### Usage

There a three main steps to implementing a simulation within this project.

1. Implement a suitable networking class by extending [`BaseNetwork`](lib/networks/BaseNetwork.m).
   For most cases, the network implementations provided by the project should suffice, so check these first before implementing your own.
2. Implement the desired agent behaviour by extending [`BaseAgent`](lib/agents/BaseAgent.m).
   The main work is in implementing the `step()` function that calculates a single discrete timestep for the agent and some minor work is in defining the projections `position` and `velocity`.
   This implementation can use the dynamic systems defined in [`lib/dynamics/`](lib/dynamics).
   For examples, see [`FlockingAgent`](examples/flocking/FlockingAgent.m) or [`FormationQuadrotor`](examples/lti_formation_control/FormationQuadrotor.m).
3. Implement the main simulation loop by calling `Agent.simulate()` and `Network.process()` in lockstep.
   At each timestep, you should save the current position of the agents if you want to animate their movement later on.

### Example Simulations

In the [`examples/`](examples) folder, you find several example simulations build with this library.
There are currently the following examples

* [Flocking](examples/flocking): Implements a flocking simulation with double integrator agents in 2D space.
* [Source Seeking](examples/flocking_with_source_seeking): Extension of the previous example with a source seeking group objective.
* [Formation Control](lti_formation_control): Formation control for linearized quadrotor models in 3D space.

Executing the `Simulation.m` script will run the simulation and animate the result.

---

### Using the SINR Networking Library

The [`SinrNetwork`](lib/networks/sinr/SinrNetwork.m) internally uses a C++ network simulation library developed by Daniel Schneider from the University of Koblenz.
For Matlab to be able to call the networking code, the library is wrapped in a compiled MEX interface.
All this is transparant to users of this library, but the computer running the simulation will have to be prepared.

#### Setting up the Matlab MEX Compiler

Before running simulations with the SINR library, the C++ library and its Matlab MEX wrapper have to be compiled first.
This is done automatically when constructing a [`SinrNetwork`](lib/networks/sinr/SinrNetwork.m) object if Matlab is set up correctly.
To configure Matlab, run the following command:

```matlab
mex -setup C++
```

Matlab should print something like

> MEX configured to use 'MinGW64 Compiler (C++)' for C++ language compilation.

if it is configured correctly.
Otherwise you probably need to install a C++ compiler for your operating system.
If you are working on Windows, you can install a suitable compiler from the Matlab *Add-On Explorer*.
Search for [MATLAB Support for MinGW-w64 C/C++ Compiler](https://de.mathworks.com/matlabcentral/fileexchange/52848-matlab-support-for-mingw-w64-c-c-compiler) from within Matlab, install the package and afterwards run the `mex` command again.

When you construct a SinrNetwork object, Matlab should now print the following in the command window.

> SINR networking library needs to be rebuild.
>
> Building...
>
> Building succeeded!
