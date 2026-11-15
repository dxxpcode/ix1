# Shared design-system kit — the single physical home of Theme,
# GradientText, ShimmerText, CheckMark, the Geist Medium faces, the
# line-icon set and the logo. Each app lists these same source files
# inside its own qt_add_qml_module (its own URI), so a fix here lands
# in every consumer. Include AFTER qt_standard_project_setup and use:
#   qt_add_qml_module(<app> URI <AppUri> ...
#       QML_FILES ${IX1_UI_QML_FILES} qml/Main.qml ...
#       RESOURCES ${IX1_UI_RESOURCES})
# Resources keep their `assets/...` alias, so consumers address them
# as qrc:/<AppUri>/assets/<file> — same as a locally owned asset.

set(IX1_UI_DIR ${CMAKE_CURRENT_LIST_DIR})

set(IX1_UI_QML_FILES
    ${IX1_UI_DIR}/qml/Theme.qml
    ${IX1_UI_DIR}/qml/GradientText.qml
    ${IX1_UI_DIR}/qml/ShimmerText.qml
    ${IX1_UI_DIR}/qml/CheckMark.qml
)

set_source_files_properties(${IX1_UI_DIR}/qml/Theme.qml
    PROPERTIES QT_QML_SINGLETON_TYPE TRUE)

set(IX1_UI_RESOURCES
    ${IX1_UI_DIR}/assets/logo.png
    ${IX1_UI_DIR}/assets/logo-light.png
    ${IX1_UI_DIR}/assets/logo-white.png
    ${IX1_UI_DIR}/assets/icons/drive.svg
    ${IX1_UI_DIR}/assets/icons/nvme.svg
    ${IX1_UI_DIR}/assets/icons/usb.svg
    ${IX1_UI_DIR}/assets/icons/shield.svg
    ${IX1_UI_DIR}/assets/icons/user.svg
    ${IX1_UI_DIR}/assets/icons/at.svg
    ${IX1_UI_DIR}/assets/icons/lock.svg
    ${IX1_UI_DIR}/assets/icons/key.svg
    ${IX1_UI_DIR}/assets/icons/eye.svg
    ${IX1_UI_DIR}/assets/icons/eye-off.svg
    ${IX1_UI_DIR}/assets/icons/wifi.svg
    ${IX1_UI_DIR}/assets/fonts/geist-500.ttf
    ${IX1_UI_DIR}/assets/fonts/geistmono-500.ttf
)

# Aliases keep each file at qrc:/<AppUri>/<dir>/<file> — the same path
# it would occupy as a locally owned file.
foreach(res IN LISTS IX1_UI_RESOURCES IX1_UI_QML_FILES)
    file(RELATIVE_PATH alias ${IX1_UI_DIR} ${res})
    set_source_files_properties(${res}
        PROPERTIES QT_RESOURCE_ALIAS ${alias})
endforeach()
