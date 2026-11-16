cmake_minimum_required(VERSION 3.21)
project(ix1-settings LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 REQUIRED COMPONENTS Quick DBus)
qt_standard_project_setup()

qt_add_executable(ix1-settings
    src/main.cpp
    src/backend.cpp
    src/backend.h
)

target_link_libraries(ix1-settings PRIVATE Qt6::Quick Qt6::DBus)

set_source_files_properties(qml/Theme.qml PROPERTIES QT_QML_SINGLETON_TYPE TRUE)

qt_add_qml_module(ix1-settings
    URI Ix1Settings
    VERSION 1.0
    QML_FILES
        qml/Theme.qml
        qml/Main.qml
        qml/PersonalizationPage.qml
        qml/DisplayPage.qml
        qml/PowerPage.qml
        qml/ui/PageHeader.qml
        qml/ui/SectionLabel.qml
        qml/ui/SettingsGroup.qml
        qml/ui/SettingsRow.qml
        qml/ui/IxSegmented.qml
        qml/ui/IxSelect.qml
        qml/ui/IxSlider.qml
        qml/ui/NavIcon.qml
        qml/ui/Sidebar.qml
        qml/ui/SunGlyph.qml
        qml/SoundPage.qml
        qml/NetworkPage.qml
        qml/UpdatesPage.qml
        qml/AboutPage.qml
    RESOURCES
        qml/assets/logo-dark.png
        qml/assets/logo-light.png
)

install(TARGETS ix1-settings RUNTIME DESTINATION bin)
