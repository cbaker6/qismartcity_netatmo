# qismartcity_netatmo

Baseline code for Qualcomm Institute (Calit2) Smart City project at the University of California - San Diego using Netatmo. All code is written in Swift. Project provides a simple login screen to netatmo with the ability to view public station information in San Diego, Los Angeles, San Francisco, and New York. Data from each sensor is graphed using Charts. The ability to view private stations is in the project, but is currently not tied to the view controllers.

In order to use the applicaiton, you must create an account on https://dev.netatmo.com as well as "Create an App" on netatmo. Afterwards, be sure to include your "Client Id" and "Client Secret" in the "SmartCityConstants.swift" file.

Original netatmo code was used from Thomas Kluge (https://github.com/thkl/NetatmoSwift). Modifications were made and additional code was added to provide the funcionality in this project

In order for the code to work, you also need to add Charts (https://github.com/danielgindi/Charts) to the project. The easiest way to do this is via cocoapods, "pod 'Charts'".