# Permissions for static sdk services
PRODUCT_COPY_FILES += \
    vendor/static/config/permissions/org.staticos.globalactions.xml:$(TARGET_COPY_OUT_PRODUCT)/etc/permissions/org.staticos.globalactions.xml \
    vendor/static/config/permissions/org.staticos.hardware.xml:$(TARGET_COPY_OUT_PRODUCT)/etc/permissions/org.staticos.hardware.xml \
    vendor/static/config/permissions/org.statics.health.xml:$(TARGET_COPY_OUT_PRODUCT)/etc/permissions/org.staticos.health.xml \
    vendor/static/config/permissions/org.staticos.livedisplay.xml:$(TARGET_COPY_OUT_PRODUCT)/etc/permissions/org.staticos.livedisplay.xml \
    vendor/static/config/permissions/org.staticos.profiles.xml:$(TARGET_COPY_OUT_PRODUCT)/etc/permissions/org.staticos.profiles.xml \
    vendor/static/config/permissions/org.staticos.settings.xml:$(TARGET_COPY_OUT_PRODUCT)/etc/permissions/org.staticos.settings.xml \
    vendor/static/config/permissions/org.staticos.trust.xml:$(TARGET_COPY_OUT_PRODUCT)/etc/permissions/org.staticos.trust.xml

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
