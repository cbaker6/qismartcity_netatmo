# Qi Smartcity Netatmo

Baseline code for Qualcomm Institute (Calit2) Smart City project at the University of California - San Diego using Netatmo. All code is written in Swift. Project provides a simple login screen to netatmo with the ability to view public station information in San Diego, Los Angeles, San Francisco, and New York. Data from each sensor is graphed using Charts. The functionality to view private station information is in the project, but is currently not tied to the view controllers.

In order to use the applicaiton, you must create an account on https://dev.netatmo.com as well as "Create an App" on netatmo. Afterwards, be sure to include your "Client Id" and "Client Secret" in the "QiSmartCityConstants.swift" file.

Much of the netatmo code is original code from Thomas Kluge (https://github.com/thkl/NetatmoSwift). Additional code for netatmo has been added along with modifications to access public netatmo data and other funcionality in this project.

In order for the project to work, you also need to add Charts (https://github.com/danielgindi/Charts) to the project. The easiest way to do this is via cocoapods. Install cocoa pods and use terminal in the main directory of this project and type "pod install". If you don't want use the podfile from this repo, add "pod 'Charts" to your own podfile.dd

![alt tag](https://cloud.githubusercontent.com/assets/8621344/15278135/f9f20ad4-1ac8-11e6-821a-912ddcb05939.jpg)
![alt tag](https://cloud.githubusercontent.com/assets/8621344/15278140/06c0d75e-1ac9-11e6-984a-3cc5df1249f7.jpg)