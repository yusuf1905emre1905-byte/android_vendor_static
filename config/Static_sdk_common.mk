# Permissions for lineage sdk services
PRODUCT_COPY_FILES += \
    vendor/static/config/permissions/org.lineageos.globalactions.xml:$(TARGET_COPY_OUT_PRODUCT)/etc/permissions/org.lineageos.globalactions.xml \
    vendor/static/config/permissions/org.lineageos.hardware.xml:$(TARGET_COPY_OUT_PRODUCT)/etc/permissions/org.lineageos.hardware.xml \
    vendor/static/config/permissions/org.lineageos.health.xml:$(TARGET_COPY_OUT_PRODUCT)/etc/permissions/org.lineageos.health.xml \
    vendor/static/config/permissions/org.lineageos.livedisplay.xml:$(TARGET_COPY_OUT_PRODUCT)/etc/permissions/org.lineageos.livedisplay.xml \
    vendor/static/config/permissions/org.lineageos.profiles.xml:$(TARGET_COPY_OUT_PRODUCT)/etc/permissions/org.lineageos.profiles.xml \
    vendor/static/config/permissions/org.lineageos.settings.xml:$(TARGET_COPY_OUT_PRODUCT)/etc/permissions/org.lineageos.settings.xml \
    vendor/static/config/permissions/org.lineageos.trust.xml:$(TARGET_COPY_OUT_PRODUCT)/etc/permissions/org.lineageos.trust.xml

# Static Platform Library
PRODUCT_PACKAGES += \
    org.staticos.platform-res \
    org.staticos.platform

# AOSP has no support of loading framework resources from /system_ext
# so the SDK has to stay in /system for now
PRODUCT_ARTIFACT_PATH_REQUIREMENT_ALLOWED_LIST += \
    system/framework/org.staticos.platform-res.apk \
    system/framework/org.staticos.platform.jar

# Allow-list odex and vdex when OVERRIDE_DISABLE_DEXOPT_ALL isn't set.
# OVERRIDE_DISABLE_DEXOPT_ALL is usually set to true for eng builds. We allow-list the below mainly for user and userdebug builds.
# Refer build/target/product/runtime_libart.mk.
ifneq ($(OVERRIDE_DISABLE_DEXOPT_ALL),true)
PRODUCT_ARTIFACT_PATH_REQUIREMENT_ALLOWED_LIST += \
    system/framework/oat/%/org.staticos.platform.odex \
    system/framework/oat/%/org.staticos.platform.vdex
endif
