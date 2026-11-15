cmake_minimum_required(VERSION 3.21)
project(ix1-installer LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 REQUIRED COMPONENTS Quick)
qt_standard_project_setup()

qt_add_executable(ix1-installer
    src/main.cpp
    src/backend.cpp
    src/backend.h
)

target_link_libraries(ix1-installer PRIVATE Qt6::Quick)

set_source_files_properties(qml/Theme.qml PROPERTIES QT_QML_SINGLETON_TYPE TRUE)

qt_add_qml_module(ix1-installer
    URI Ix1Installer
    VERSION 1.0
    QML_FILES
        qml/Main.qml
        qml/Theme.qml
        qml/GradientText.qml
        qml/ShimmerText.qml
        qml/CheckMark.qml
        qml/DestinationPage.qml
        qml/AccountPage.qml
        qml/DeployPage.qml
    RESOURCES
        assets/logo.png
        assets/logo-light.png
        assets/logo-white.png
        assets/icons/drive.svg
        assets/icons/nvme.svg
        assets/icons/usb.svg
        assets/icons/shield.svg
        assets/fonts/geist-500.ttf
        assets/fonts/geistmono-500.ttf
)

install(TARGETS ix1-installer RUNTIME DESTINATION bin)
