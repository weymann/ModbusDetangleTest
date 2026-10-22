# Test cases: `bundleSymbolicName` in thing types

This document describes, step by step, the test cases for the new `bundleSymbolicName` property
(commit `2f899656d`, bundle `org.openhab.core.thing`).

## Background

A `ThingType` now knows the symbolic name of the bundle that provides it.
This allows a thing type to be related to an add-on. The value is passed along as follows:

1. `ThingTypeXmlProvider` reads the value from the bundle (`bundle.getSymbolicName()`).
1. `ThingTypeXmlResult` hands it to the `ThingTypeBuilder`.
1. `ThingType` and `BridgeType` hold it and expose it via `getBundleSymbolicName()`.
1. `StrippedThingTypeDTOMapper` sets it in the `StrippedThingTypeDTO` (REST).
1. `AbstractStorageBasedTypeProvider` stores it in the `ThingTypeEntity` and restores it.

## Overview

| No. | Test class | Test method | Verifies |
|-----|------------|-------------|----------|
| 1 | `ThingTypeBuilderTest` | `bundleSymbolicNameIsKeptForThingTypeAndBridgeType` | Value is kept for thing type, bridge type and copy |
| 2 | `ThingTypeBuilderTest` | `bundleSymbolicNameIsNullByDefault` | Value is `null` if not set |
| 3 | `StrippedThingTypeDTOMapperTest` | `bundleSymbolicNameIsMapped` | Value ends up in the DTO |
| 4 | `StrippedThingTypeDTOMapperTest` | `bundleSymbolicNameIsNullWithoutBundle` | DTO value is `null` without a bundle |
| 5 | `AbstractStorageBasedTypeProviderTest` | `testMapToEntityIsComplete` (parameter `ThingType`) | Storage entity maps all fields of `ThingType` |

All test classes are located under `bundles/org.openhab.core.thing/src/test/java/org/openhab/core/thing/`.

## Test case 1: value is kept

Class `type/ThingTypeBuilderTest`, method `bundleSymbolicNameIsKeptForThingTypeAndBridgeType`.

1. Configure the builder with `withBundleSymbolicName("org.openhab.binding.test")` and call `build()`.
1. Expected: `thingType.getBundleSymbolicName()` returns `org.openhab.binding.test`.
1. Call `buildBridge()` on the same builder.
1. Expected: `bridgeType.getBundleSymbolicName()` also returns `org.openhab.binding.test`.
1. Copy the finished thing type into a new builder (`ThingTypeBuilder.instance(thingType).build()`).
1. Expected: the copy still returns `org.openhab.binding.test`.

## Test case 2: default value is `null`

Class `type/ThingTypeBuilderTest`, method `bundleSymbolicNameIsNullByDefault`.

1. Use the builder without calling `withBundleSymbolicName(...)` and call `build()`.
1. Expected: `getBundleSymbolicName()` returns `null`.

## Test case 3: mapping into the DTO

Class `dto/StrippedThingTypeDTOMapperTest`, method `bundleSymbolicNameIsMapped`.

1. Build the thing type `binding:type` with label `Label` and bundle name `org.openhab.binding.test`.
1. Call `StrippedThingTypeDTOMapper.map(thingType, Locale.ENGLISH)`.
1. Expected: `dto.UID` is `binding:type`.
1. Expected: `dto.bundleSymbolicName` is `org.openhab.binding.test`.

## Test case 4: DTO without a bundle

Class `dto/StrippedThingTypeDTOMapperTest`, method `bundleSymbolicNameIsNullWithoutBundle`.

1. Build a thing type without a bundle name.
1. Call `StrippedThingTypeDTOMapper.map(thingType, Locale.ENGLISH)`.
1. Expected: `dto.bundleSymbolicName` is `null`.

## Test case 5: storage entity is complete

Class `binding/AbstractStorageBasedTypeProviderTest`, method `testMapToEntityIsComplete`.

This test already existed. It failed after the commit because `ThingTypeEntity` lacked the new field.

1. Count all declared fields of `ThingType` and its superclasses (up to `Object`) via reflection.
1. Count the fields of `AbstractStorageBasedTypeProvider.ThingTypeEntity`.
1. Expected: entity fields = `ThingType` fields + 1. The additional field is `isBridge`.
1. Before the fix: 14 instead of 15. After the fix: `bundleSymbolicName` is added to the entity,
   and the value is transferred in `mapToEntity` and `mapFromEntity`.

## Running the tests

Only the affected test classes, from the repository root:

```bash
mvn test -pl bundles/org.openhab.core.thing -Dtest="ThingTypeBuilderTest,StrippedThingTypeDTOMapperTest,AbstractStorageBasedTypeProviderTest"
```

Full build without aborting on failing tests:

```bash
mvn clean install -Dmaven.test.failure.ignore=true
```

Results are written to `bundles/org.openhab.core.thing/target/surefire-reports`.

## Known gap (not part of this commit)

`semanticEquipmentTag` exists in `ThingTypeEntity` but is not set in `mapToEntity` or `mapFromEntity`.
There is no test case for this yet. The field count in test case 5 does not detect it.
