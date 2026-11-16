cmake_minimum_required(VERSION 3.21)
project(ix1-shell LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 REQUIRED COMPONENTS Quick DBus)
find_package(KF6IdleTime REQUIRED)
find_package(KF6WindowSystem REQUIRED)
qt_standard_project_setup()

qt_add_executable(ix1-shell
    src/main.cpp
    src/backend.cpp
    src/backend.h
    src/notifications.cpp
    src/notifications.h
)

target_link_libraries(ix1-shell PRIVATE
    Qt6::Quick
    Qt6::DBus
    KF6::IdleTime
    KF6::WindowSystem
    pam
)

set_source_files_properties(qml/Theme.qml qml/cc/CcStyle.qml PROPERTIES QT_QML_SINGLETON_TYPE TRUE)

qt_add_qml_module(ix1-shell
    URI Ix1Shell
    VERSION 1.0
    QML_FILES
        qml/Theme.qml
        qml/AppIcon.qml
        qml/Wallpaper.qml
        qml/Panel.qml
        qml/Dock.qml
        qml/Launcher.qml
        qml/QuickSettings.qml
        qml/cc/CcStyle.qml
        qml/cc/CcIcon.qml
        qml/cc/CcTile.qml
        qml/cc/CcSlider.qml
        qml/cc/CcCircleButton.qml
        qml/cc/CcListRow.qml
        qml/cc/CcExpander.qml
        qml/cc/CcDevicePicker.qml
        qml/Calendar.qml
        qml/Notifications.qml
        qml/LockScreen.qml
    RESOURCES
        qml/assets/wallpaper-graphite.png
        qml/assets/wallpaper-porcelain.png
        qml/assets/logo-dark.png
        qml/assets/logo-light.png
        qml/assets/icons/settings.png
        qml/assets/icons/terminal.png
        qml/assets/icons/files.png
        qml/assets/icons/editor.png
        qml/assets/icons/monitor.png
        qml/assets/icons/browser.png
        qml/assets/icons/pulse.png
        qml/assets/icons/bars.png
        qml/assets/icons/grid.png
        qml/assets/icons/store.png
        qml/assets/geist-500.ttf
        qml/assets/geistmono-500.ttf
        qml/assets/fonts/NotoSans-Regular.ttf
        qml/assets/fonts/NotoSans-Medium.ttf
        qml/assets/fonts/NotoSans-SemiBold.ttf
)

install(TARGETS ix1-shell RUNTIME DESTINATION bin)
install(FILES kwin/active-window.js DESTINATION share/ix1/kwin)
