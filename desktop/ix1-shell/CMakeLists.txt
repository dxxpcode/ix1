cmake_minimum_required(VERSION 3.21)
project(ix1-shell LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 REQUIRED COMPONENTS Quick DBus)
find_package(KF6IdleTime REQUIRED)
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
    pam
)

set_source_files_properties(qml/Theme.qml PROPERTIES QT_QML_SINGLETON_TYPE TRUE)

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
        qml/Squircle.qml
        qml/cc/StatusLine.qml
        qml/cc/SheetSection.qml
        qml/cc/SwitchRow.qml
        qml/cc/GlyphButton.qml
        qml/cc/SegmentedControl.qml
        qml/cc/CapsuleSlider.qml
        qml/cc/SheetTile.qml
        qml/cc/Glyph.qml
        qml/cc/KnobSlider.qml
        qml/cc/PowerCircle.qml
        qml/cc/DropdownPill.qml
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
        qml/assets/icons-lucide/wifi.svg
        qml/assets/icons-lucide-dark/wifi.svg
        qml/assets/icons-lucide/bluetooth.svg
        qml/assets/icons-lucide-dark/bluetooth.svg
        qml/assets/icons-lucide/moon.svg
        qml/assets/icons-lucide-dark/moon.svg
        qml/assets/icons-lucide/moon-star.svg
        qml/assets/icons-lucide-dark/moon-star.svg
        qml/assets/icons-lucide/sun.svg
        qml/assets/icons-lucide-dark/sun.svg
        qml/assets/icons-lucide/sun-medium.svg
        qml/assets/icons-lucide-dark/sun-medium.svg
        qml/assets/icons-lucide/volume-2.svg
        qml/assets/icons-lucide-dark/volume-2.svg
        qml/assets/icons-lucide/lock.svg
        qml/assets/icons-lucide-dark/lock.svg
        qml/assets/icons-lucide/power.svg
        qml/assets/icons-lucide-dark/power.svg
        qml/assets/icons-lucide/refresh-cw.svg
        qml/assets/icons-lucide-dark/refresh-cw.svg
        qml/assets/icons-lucide/headphones.svg
        qml/assets/icons-lucide-dark/headphones.svg
        qml/assets/icons-lucide/sliders-horizontal.svg
        qml/assets/icons-lucide-dark/sliders-horizontal.svg
        qml/assets/icons-lucide/chevron-right.svg
        qml/assets/icons-lucide-dark/chevron-right.svg
        qml/assets/icons-lucide/chevron-down.svg
        qml/assets/icons-lucide-dark/chevron-down.svg
        qml/assets/icons-lucide/settings.svg
        qml/assets/icons-lucide-dark/settings.svg
        qml/assets/icons-lucide/check.svg
        qml/assets/icons-lucide-dark/check.svg
        qml/assets/icons-lucide/signal.svg
        qml/assets/icons-lucide-dark/signal.svg
        qml/assets/geist-500.ttf
        qml/assets/geistmono-500.ttf
)

install(TARGETS ix1-shell RUNTIME DESTINATION bin)
install(FILES kwin/active-window.js DESTINATION share/ix1/kwin)
