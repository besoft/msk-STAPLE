# auto-msk-model
repository to develop automated methods for generating musculoskeletal models from segmented anatomical structures

# Plan
The MSK models are built using the following approaches:

# Summary of implemented methods

| Bone                 | Rigid Body | Joint Coordinate System | Algorithms |
| ---                  | ---     | ---                     | ---        |
| Pelvis               | pelvis  | ground-pelvis | STAPLE-Pelvis |
|                      |         | ground-pelvis | Kai-Pelvis    |
| Femur                | femur   | hip child     | Kai-Femur     |
|                      |         |               | GIBOC-Femur   |
| Tibia+Fibula         | fibula  |  |  |
| Patella              | patella |  |  |
| Talus                | talus   |  |  |
| Calcaneus+Foot bones | calcn   |  |  |
| Phalanges            | toes    |  |  |

* pelvis: using inertial axes
* femur:
    1. Kai et al. 2014
    2. Miranda et al. 2010
    3. Renault et al. 2018
* tibia:
    1. Kai et al. 2014
    2. Miranda et al. 2010
    3. Renault et al. 2018
* patella:
    1. Rainbow et al. 2010
    2. Renault et al. 2018
* talus:
    1. this study

# Requirements
Requires:
* MATLAB 2017a or more recent
* OpenSim v4.0 or higher

# Test geometries
Test geometries are available for developers (DO NOT REDISTRIBUTE!) at [this link](https://www.dropbox.com/sh/wk4izo66qxbxp3h/AABAcyxpHkfWy1v5AjJ7QOIYa?dl=0).
You can simply copy them in the "test_geometries" directory and adapt the scripts.

# Further Development
* Segment mass properties and degrees of freedom of the joint models can easily be customised. 
* The sagittal profile of femoral condyles is available and could be used to personalized knee joint models like Yamaguchi's knee in combination with the automated slope estimation presented by Amirtharaj et al. (2018).


# TO DO
- [ ] Streamline MSK workflow
- [ ] fit patellar groove as in [Sancisi et al](https://www.dropbox.com/s/diajesc737ujdsd/SancisiJMR11.pdf?dl=0) and [Da Luz et al](https://www.dropbox.com/s/ah4di27b0hhsrhi/Brito%20da%20Luz-2017-Feasibility%20of%20using%20MRIs%20to.pdf?dl=0)




