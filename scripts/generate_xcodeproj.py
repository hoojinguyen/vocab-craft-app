import os
import hashlib

def generate_id(prefix, path):
    # Generates a 24-character hex ID compatible with Xcode PBX object IDs
    h = hashlib.sha1(path.encode('utf-8')).hexdigest()[:16].upper()
    return f"{prefix}{h}"

def scan_files(base_dir):
    file_paths = []
    for root, _, files in os.walk(base_dir):
        for file in files:
            if file.endswith('.swift') or file.endswith('.plist') or file.endswith('.entitlements') or file.endswith('.xcstrings') or file.endswith('.json') or file.endswith('.xcassets'):
                full_path = os.path.join(root, file)
                file_paths.append(full_path)
    file_paths.sort()
    return file_paths

def get_file_type(filename):
    if filename.endswith(".swift"):
        return "sourcecode.swift"
    elif filename.endswith(".plist"):
        return "text.plist.xml"
    elif filename.endswith(".entitlements"):
        return "text.plist.entitlements"
    elif filename.endswith(".xcstrings"):
        return "text.json.xcstrings"
    elif filename.endswith(".json"):
        return "text.json"
    elif filename.endswith(".xcassets"):
        return "folder.assetcatalog"
    return "text"

def generate_pbxproj():
    app_files = scan_files("VocabCraftApp")
    test_files = scan_files("VocabCraftAppTests")
    widget_files = scan_files("VocabCraftWidgetExtension")

    # Widget shared files from main app
    widget_shared_files = [
        "VocabCraftApp/Core/Database/DatasetEngine.swift",
        "VocabCraftApp/Core/Database/SharedAppGroupContainer.swift",
        "VocabCraftApp/Core/Database/SwiftDataModels.swift",
        "VocabCraftApp/Core/Database/DatasetModels.swift",
        "VocabCraftApp/Core/SRS/SRSEngine.swift",
        "VocabCraftApp/Domain/Protocols/DatasetDataSourceProtocol.swift"
    ]

    pbx_build_files = []
    pbx_file_refs = []
    app_sources_build_files = []
    app_resources_build_files = []
    widget_sources_build_files = []
    test_sources_build_files = []

    # Process App Files
    for path in app_files:
        filename = os.path.basename(path)
        ref_id = generate_id("2000", path)
        build_id = generate_id("3000", path)

        file_type = get_file_type(filename)
        pbx_file_refs.append(f'\t\t{ref_id} /* {filename} */ = {{isa = PBXFileReference; lastKnownFileType = {file_type}; path = "{filename}"; sourceTree = "<group>"; }};')

        if filename.endswith(".swift"):
            pbx_build_files.append(f'\t\t{build_id} /* {filename} in Sources */ = {{isa = PBXBuildFile; fileRef = {ref_id} /* {filename} */; }};')
            app_sources_build_files.append(f'\t\t\t\t{build_id} /* {filename} in Sources */,')
        elif filename.endswith(".xcstrings") or filename.endswith(".json") or filename.endswith(".xcassets"):
            pbx_build_files.append(f'\t\t{build_id} /* {filename} in Resources */ = {{isa = PBXBuildFile; fileRef = {ref_id} /* {filename} */; }};')
            app_resources_build_files.append(f'\t\t\t\t{build_id} /* {filename} in Resources */,')

    # Process Widget Files
    for path in widget_files:
        filename = os.path.basename(path)
        ref_id = generate_id("2000", path)
        build_id = generate_id("3000", path)

        file_type = get_file_type(filename)
        pbx_file_refs.append(f'\t\t{ref_id} /* {filename} */ = {{isa = PBXFileReference; lastKnownFileType = {file_type}; path = "{filename}"; sourceTree = "<group>"; }};')

        if filename.endswith(".swift"):
            pbx_build_files.append(f'\t\t{build_id} /* {filename} in Widget Sources */ = {{isa = PBXBuildFile; fileRef = {ref_id} /* {filename} */; }};')
            widget_sources_build_files.append(f'\t\t\t\t{build_id} /* {filename} in Widget Sources */,')
            test_build_id = generate_id("3002", path + "_test")
            pbx_build_files.append(f'\t\t{test_build_id} /* {filename} in Test Sources */ = {{isa = PBXBuildFile; fileRef = {ref_id} /* {filename} */; }};')
            test_sources_build_files.append(f'\t\t\t\t{test_build_id} /* {filename} in Test Sources */,')

    # Process Widget Shared Files
    for path in widget_shared_files:
        filename = os.path.basename(path)
        ref_id = generate_id("2000", path)
        build_id = generate_id("3001", path + "_widget")
        pbx_build_files.append(f'\t\t{build_id} /* {filename} in Widget Sources */ = {{isa = PBXBuildFile; fileRef = {ref_id} /* {filename} */; }};')
        widget_sources_build_files.append(f'\t\t\t\t{build_id} /* {filename} in Widget Sources */,')

    # Process Test Files
    for path in test_files:
        filename = os.path.basename(path)
        ref_id = generate_id("2000", path)
        build_id = generate_id("3000", path)

        file_type = get_file_type(filename)
        pbx_file_refs.append(f'\t\t{ref_id} /* {filename} */ = {{isa = PBXFileReference; lastKnownFileType = {file_type}; path = "{filename}"; sourceTree = "<group>"; }};')

        if filename.endswith(".swift"):
            pbx_build_files.append(f'\t\t{build_id} /* {filename} in Test Sources */ = {{isa = PBXBuildFile; fileRef = {ref_id} /* {filename} */; }};')
            test_sources_build_files.append(f'\t\t\t\t{build_id} /* {filename} in Test Sources */,')

    # Helper for creating group structure recursively
    def create_groups_for_dir(dir_path, group_id_prefix):
        children = []
        entries = sorted(os.listdir(dir_path))
        group_entries = []

        for entry in entries:
            full_path = os.path.join(dir_path, entry)
            if os.path.isdir(full_path):
                child_group_id = generate_id("4000", full_path)
                children.append(f'\t\t\t\t{child_group_id} /* {entry} */,')
                group_entries.extend(create_groups_for_dir(full_path, "4000"))
            elif entry.endswith(".swift") or entry.endswith(".plist") or entry.endswith(".entitlements") or entry.endswith(".xcstrings") or entry.endswith(".json") or entry.endswith(".xcassets"):
                file_ref_id = generate_id("2000", full_path)
                children.append(f'\t\t\t\t{file_ref_id} /* {entry} */,')

        group_id = generate_id(group_id_prefix, dir_path)
        group_str = f"""\t\t{group_id} /* {os.path.basename(dir_path)} */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
""" + "\n".join(children) + f"""
\t\t\t);
\t\t\tpath = "{os.path.basename(dir_path)}";
\t\t\tsourceTree = "<group>";
\t\t}};"""
        group_entries.insert(0, group_str)
        return group_entries

    app_group_str = "\n".join(create_groups_for_dir("VocabCraftApp", "4000"))
    test_group_str = "\n".join(create_groups_for_dir("VocabCraftAppTests", "4000"))
    widget_group_str = "\n".join(create_groups_for_dir("VocabCraftWidgetExtension", "4000"))

    app_root_id = generate_id("4000", "VocabCraftApp")
    test_root_id = generate_id("4000", "VocabCraftAppTests")
    widget_root_id = generate_id("4000", "VocabCraftWidgetExtension")

    pbx_build_section = "\n".join(pbx_build_files)
    pbx_file_ref_section = "\n".join(pbx_file_refs)
    app_sources_section = "\n".join(app_sources_build_files)
    app_resources_section = "\n".join(app_resources_build_files)
    widget_sources_section = "\n".join(widget_sources_build_files)
    test_sources_section = "\n".join(test_sources_build_files)

    content = f"""// !$*UTF8*$!
{{
	archiveVersion = 1;
	classes = {{
	}};
	objectVersion = 60;
	objects = {{

/* Begin PBXBuildFile section */
{pbx_build_section}
		300000402D50000000000002 /* VocabCraftWidgetExtension.appex in Embed App Extensions */ = {{isa = PBXBuildFile; fileRef = 200000402D50000000000000 /* VocabCraftWidgetExtension.appex */; settings = {{ATTRIBUTES = (RemoveHeadersOnCopy, CodeSignOnCopy, ); }}; }};
		900000000000000000000003 /* CraftUIKit in Frameworks */ = {{isa = PBXBuildFile; productRef = 900000000000000000000002 /* CraftUIKit */; }};
		900000000000000000000004 /* CraftUIKit in Frameworks */ = {{isa = PBXBuildFile; productRef = 900000000000000000000002 /* CraftUIKit */; }};
		900000000000000000000007 /* SpeechKit in Frameworks */ = {{isa = PBXBuildFile; productRef = 900000000000000000000006 /* SpeechKit */; }};
		900000000000000000000008 /* SpeechKit in Frameworks */ = {{isa = PBXBuildFile; productRef = 900000000000000000000006 /* SpeechKit */; }};
/* End PBXBuildFile section */

/* Begin PBXContainerItemProxy section */
		700000402D50000000000001 /* PBXContainerItemProxy */ = {{
			isa = PBXContainerItemProxy;
			containerPortal = 100000002D50000000000000 /* Project object */;
			proxyType = 1;
			remoteGlobalIDString = 600000022D50000000000000;
			remoteInfo = VocabCraftWidgetExtension;
		}};
		700000502D50000000000001 /* PBXContainerItemProxy */ = {{
			isa = PBXContainerItemProxy;
			containerPortal = 100000002D50000000000000 /* Project object */;
			proxyType = 1;
			remoteGlobalIDString = 600000012D50000000000000;
			remoteInfo = VocabCraftApp;
		}};
/* End PBXContainerItemProxy section */

/* Begin PBXCopyFilesBuildPhase section */
		100000002D50000000000099 /* Embed App Extensions */ = {{
			isa = PBXCopyFilesBuildPhase;
			buildActionMask = 2147483647;
			dstPath = "";
			dstSubfolderSpec = 13;
			files = (
				300000402D50000000000002 /* VocabCraftWidgetExtension.appex in Embed App Extensions */,
			);
			name = "Embed App Extensions";
			runOnlyForDeploymentPostprocessing = 0;
		}};
/* End PBXCopyFilesBuildPhase section */

/* Begin PBXFileReference section */
		200000002D50000000000000 /* VocabCraftApp.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = VocabCraftApp.app; sourceTree = BUILT_PRODUCTS_DIR; }};
		200000402D50000000000000 /* VocabCraftWidgetExtension.appex */ = {{isa = PBXFileReference; explicitFileType = "wrapper.app-extension"; includeInIndex = 0; path = VocabCraftWidgetExtension.appex; sourceTree = BUILT_PRODUCTS_DIR; }};
		200000502D50000000000000 /* VocabCraftAppTests.xctest */ = {{isa = PBXFileReference; explicitFileType = wrapper.cfbundle; includeInIndex = 0; path = VocabCraftAppTests.xctest; sourceTree = BUILT_PRODUCTS_DIR; }};
{pbx_file_ref_section}
/* End PBXFileReference section */

/* Begin PBXFrameworksBuildPhase section */
		100000012D50000000000000 /* Frameworks */ = {{
			isa = PBXFrameworksBuildPhase;
			buildActionMask = 2147483647;
			files = (
				900000000000000000000003 /* CraftUIKit in Frameworks */,
				900000000000000000000007 /* SpeechKit in Frameworks */,
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
		100000402D50000000000000 /* Frameworks */ = {{
			isa = PBXFrameworksBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
		100000502D50000000000000 /* Frameworks */ = {{
			isa = PBXFrameworksBuildPhase;
			buildActionMask = 2147483647;
			files = (
				900000000000000000000004 /* CraftUIKit in Frameworks */,
				900000000000000000000008 /* SpeechKit in Frameworks */,
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
/* End PBXFrameworksBuildPhase section */

/* Begin PBXGroup section */
		400000002D50000000000000 /* MainGroup */ = {{
			isa = PBXGroup;
			children = (
				{app_root_id} /* VocabCraftApp */,
				{widget_root_id} /* VocabCraftWidgetExtension */,
				{test_root_id} /* VocabCraftAppTests */,
				400000092D50000000000000 /* Products */,
			);
			sourceTree = "<group>";
		}};
{app_group_str}
{widget_group_str}
{test_group_str}
		400000092D50000000000000 /* Products */ = {{
			isa = PBXGroup;
			children = (
				200000002D50000000000000 /* VocabCraftApp.app */,
				200000402D50000000000000 /* VocabCraftWidgetExtension.appex */,
				200000502D50000000000000 /* VocabCraftAppTests.xctest */,
			);
			name = Products;
			sourceTree = "<group>";
		}};
/* End PBXGroup section */

/* Begin PBXNativeTarget section */
		600000012D50000000000000 /* VocabCraftApp */ = {{
			isa = PBXNativeTarget;
			buildConfigurationList = 500000012D50000000000000 /* Build configuration list for PBXNativeTarget "VocabCraftApp" */;
			buildPhases = (
				100000022D50000000000000 /* Sources */,
				100000012D50000000000000 /* Frameworks */,
				100000032D50000000000000 /* Resources */,
				100000002D50000000000099 /* Embed App Extensions */,
			);
			buildRules = (
			);
			dependencies = (
				800000402D50000000000001 /* TargetDependency */,
			);
			name = VocabCraftApp;
			packageProductDependencies = (
				900000000000000000000002 /* CraftUIKit */,
				900000000000000000000006 /* SpeechKit */,
			);
			productName = VocabCraftApp;
			productReference = 200000002D50000000000000 /* VocabCraftApp.app */;
			productType = "com.apple.product-type.application";
		}};
		600000022D50000000000000 /* VocabCraftWidgetExtension */ = {{
			isa = PBXNativeTarget;
			buildConfigurationList = 500000022D50000000000000 /* Build configuration list for PBXNativeTarget "VocabCraftWidgetExtension" */;
			buildPhases = (
				100000402D50000000000002 /* Sources */,
				100000402D50000000000000 /* Frameworks */,
			);
			buildRules = (
			);
			dependencies = (
			);
			name = VocabCraftWidgetExtension;
			productName = VocabCraftWidgetExtension;
			productReference = 200000402D50000000000000 /* VocabCraftWidgetExtension.appex */;
			productType = "com.apple.product-type.app-extension";
		}};
		600000032D50000000000000 /* VocabCraftAppTests */ = {{
			isa = PBXNativeTarget;
			buildConfigurationList = 500000032D50000000000000 /* Build configuration list for PBXNativeTarget "VocabCraftAppTests" */;
			buildPhases = (
				100000502D50000000000002 /* Sources */,
				100000502D50000000000000 /* Frameworks */,
			);
			buildRules = (
			);
			dependencies = (
				800000502D50000000000001 /* TargetDependency */,
			);
			name = VocabCraftAppTests;
			packageProductDependencies = (
				900000000000000000000002 /* CraftUIKit */,
				900000000000000000000006 /* SpeechKit */,
			);
			productName = VocabCraftAppTests;
			productReference = 200000502D50000000000000 /* VocabCraftAppTests.xctest */;
			productType = "com.apple.product-type.bundle.unit-test";
		}};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
		100000002D50000000000000 /* Project object */ = {{
			isa = PBXProject;
			attributes = {{
				BuildIndependentTargetsInParallel = 1;
				LastSwiftUpdateCheck = 1540;
				LastUpgradeCheck = 1540;
				TargetAttributes = {{
					600000012D50000000000000 = {{
						CreatedOnToolsVersion = 15.4;
					}};
					600000022D50000000000000 = {{
						CreatedOnToolsVersion = 15.4;
					}};
					600000032D50000000000000 = {{
						CreatedOnToolsVersion = 15.4;
						TestTargetID = 600000012D50000000000000;
					}};
				}};
			}};
			buildConfigurationList = 500000002D50000000000000 /* Build configuration list for PBXProject "VocabCraftApp" */;
			compatibilityVersion = "Xcode 14.0";
			developmentRegion = en;
			hasScannedForEncodings = 0;
			knownRegions = (
				en,
				vi,
				Base,
			);
			mainGroup = 400000002D50000000000000 /* MainGroup */;
			packageReferences = (
				900000000000000000000001 /* XCLocalSwiftPackageReference "CraftUIKit" */,
				900000000000000000000005 /* XCLocalSwiftPackageReference "SpeechKit" */,
			);
			productRefGroup = 400000092D50000000000000 /* Products */;
			projectDirPath = "";
			projectRoot = "";
			targets = (
				600000012D50000000000000 /* VocabCraftApp */,
				600000022D50000000000000 /* VocabCraftWidgetExtension */,
				600000032D50000000000000 /* VocabCraftAppTests */,
			);
		}};
/* End PBXProject section */

/* Begin PBXResourcesBuildPhase section */
		100000032D50000000000000 /* Resources */ = {{
			isa = PBXResourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
{app_resources_section}
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
/* End PBXResourcesBuildPhase section */

/* Begin PBXSourcesBuildPhase section */
		100000022D50000000000000 /* Sources */ = {{
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
{app_sources_section}
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
		100000402D50000000000002 /* Sources */ = {{
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
{widget_sources_section}
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
		100000502D50000000000002 /* Sources */ = {{
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
{test_sources_section}
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
/* End PBXSourcesBuildPhase section */

/* Begin PBXTargetDependency section */
		800000402D50000000000001 /* PBXTargetDependency */ = {{
			isa = PBXTargetDependency;
			target = 600000022D50000000000000 /* VocabCraftWidgetExtension */;
			targetProxy = 700000402D500000000000001 /* PBXContainerItemProxy */;
		}};
		800000502D50000000000001 /* PBXTargetDependency */ = {{
			isa = PBXTargetDependency;
			target = 600000012D50000000000000 /* VocabCraftApp */;
			targetProxy = 700000502D500000000000001 /* PBXContainerItemProxy */;
		}};
/* End PBXTargetDependency section */

/* Begin XCBuildConfiguration section */
		500000002D50000000000001 /* Debug */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ALWAYS_SEARCH_USER_PATHS = NO;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				CODE_SIGN_ENTITLEMENTS = VocabCraftApp/App/VocabCraftApp.entitlements;
				CODE_SIGN_STYLE = Automatic;
				COMPILATION_CACHE_ENABLE_CACHING = YES;
				CURRENT_PROJECT_VERSION = 1;
				DEBUG_INFORMATION_FORMAT = dwarf;
				EAGER_LINKING = YES;
				ENABLE_PREVIEWS = YES;
				ENABLE_TESTABILITY = YES;
				GCC_OPTIMIZATION_LEVEL = 0;
				GENERATE_INFOPLIST_FILE = NO;
				INFOPLIST_FILE = VocabCraftApp/App/Info.plist;
				IPHONEOS_DEPLOYMENT_TARGET = 17.0;
				MARKETING_VERSION = 1.0;
				ONLY_ACTIVE_ARCH = YES;
				PRODUCT_BUNDLE_IDENTIFIER = com.hoojinguyen.vocabcraft;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SDKROOT = iphoneos;
				SUPPORTED_PLATFORMS = "iphoneos iphonesimulator";
				SUPPORTS_MACCATALYST = NO;
				SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD = NO;
				SWIFT_COMPILATION_MODE = singlefile;
				SWIFT_OPTIMIZATION_LEVEL = "-Onone";
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = "1,2";
			}};
			name = Debug;
		}};
		500000002D50000000000002 /* Release */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ALWAYS_SEARCH_USER_PATHS = NO;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				CODE_SIGN_ENTITLEMENTS = VocabCraftApp/App/VocabCraftApp.entitlements;
				CODE_SIGN_STYLE = Automatic;
				COMPILATION_CACHE_ENABLE_CACHING = YES;
				CURRENT_PROJECT_VERSION = 1;
				DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
				ENABLE_TESTABILITY = NO;
				GCC_OPTIMIZATION_LEVEL = s;
				GENERATE_INFOPLIST_FILE = NO;
				INFOPLIST_FILE = VocabCraftApp/App/Info.plist;
				IPHONEOS_DEPLOYMENT_TARGET = 17.0;
				MARKETING_VERSION = 1.0;
				ONLY_ACTIVE_ARCH = NO;
				PRODUCT_BUNDLE_IDENTIFIER = com.hoojinguyen.vocabcraft;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SDKROOT = iphoneos;
				SUPPORTED_PLATFORMS = "iphoneos iphonesimulator";
				SUPPORTS_MACCATALYST = NO;
				SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD = NO;
				SWIFT_COMPILATION_MODE = wholemodule;
				SWIFT_OPTIMIZATION_LEVEL = "-O";
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = "1,2";
			}};
			name = Release;
		}};
		500000012D50000000000001 /* Debug */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ALWAYS_SEARCH_USER_PATHS = NO;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				CODE_SIGN_ENTITLEMENTS = VocabCraftApp/App/VocabCraftApp.entitlements;
				CODE_SIGN_STYLE = Automatic;
				COPY_PHASE_STRIP = NO;
				CURRENT_PROJECT_VERSION = 1;
				DEFINES_MODULE = NO;
				DEVELOPMENT_TEAM = 58TYVC4N97;
				ENABLE_PREVIEWS = YES;
				ENABLE_TESTABILITY = YES;
				GENERATE_INFOPLIST_FILE = NO;
				INFOPLIST_FILE = VocabCraftApp/App/Info.plist;
				IPHONEOS_DEPLOYMENT_TARGET = 17.0;
				MARKETING_VERSION = 1.0;
				ONLY_ACTIVE_ARCH = YES;
				PRODUCT_BUNDLE_IDENTIFIER = com.hoojinguyen.vocabcraft;
				PRODUCT_MODULE_NAME = VocabCraftApp;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SDKROOT = iphoneos;
				SUPPORTED_PLATFORMS = "iphoneos iphonesimulator";
				SUPPORTS_MACCATALYST = NO;
				SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD = NO;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = "1,2";
			}};
			name = Debug;
		}};

		500000012D50000000000002 /* Release */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ALWAYS_SEARCH_USER_PATHS = NO;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				CODE_SIGN_ENTITLEMENTS = VocabCraftApp/App/VocabCraftApp.entitlements;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				DEVELOPMENT_TEAM = 58TYVC4N97;
				GENERATE_INFOPLIST_FILE = NO;
				INFOPLIST_FILE = VocabCraftApp/App/Info.plist;
				IPHONEOS_DEPLOYMENT_TARGET = 17.0;
				MARKETING_VERSION = 1.0;
				ONLY_ACTIVE_ARCH = NO;
				PRODUCT_BUNDLE_IDENTIFIER = com.hoojinguyen.vocabcraft;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SDKROOT = iphoneos;
				SUPPORTED_PLATFORMS = "iphoneos iphonesimulator";
				SUPPORTS_MACCATALYST = NO;
				SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD = NO;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = "1,2";
			}};
			name = Release;
		}};
		500000022D50000000000001 /* Debug */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ALWAYS_SEARCH_USER_PATHS = NO;
				CLANG_ENABLE_MODULES = YES;
				CODE_SIGN_STYLE = Automatic;
				COPY_PHASE_STRIP = NO;
				CURRENT_PROJECT_VERSION = 1;
				DEVELOPMENT_TEAM = 58TYVC4N97;
				GENERATE_INFOPLIST_FILE = NO;
				INFOPLIST_FILE = VocabCraftWidgetExtension/Info.plist;
				IPHONEOS_DEPLOYMENT_TARGET = 17.0;
				MARKETING_VERSION = 1.0;
				ONLY_ACTIVE_ARCH = YES;
				PRODUCT_BUNDLE_IDENTIFIER = com.hoojinguyen.vocabcraft.widget;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SDKROOT = iphoneos;
				SKIP_INSTALL = YES;
				SUPPORTED_PLATFORMS = "iphoneos iphonesimulator";
				SUPPORTS_MACCATALYST = NO;
				SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD = NO;
				SWIFT_ACTIVE_COMPILATION_CONDITIONS = "WIDGET_EXTENSION $(inherited)";
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = "1,2";
			}};
			name = Debug;
		}};
		500000022D50000000000002 /* Release */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ALWAYS_SEARCH_USER_PATHS = NO;
				CLANG_ENABLE_MODULES = YES;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				DEVELOPMENT_TEAM = 58TYVC4N97;
				GENERATE_INFOPLIST_FILE = NO;
				INFOPLIST_FILE = VocabCraftWidgetExtension/Info.plist;
				IPHONEOS_DEPLOYMENT_TARGET = 17.0;
				MARKETING_VERSION = 1.0;
				ONLY_ACTIVE_ARCH = NO;
				PRODUCT_BUNDLE_IDENTIFIER = com.hoojinguyen.vocabcraft.widget;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SDKROOT = iphoneos;
				SKIP_INSTALL = YES;
				SUPPORTED_PLATFORMS = "iphoneos iphonesimulator";
				SUPPORTS_MACCATALYST = NO;
				SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD = NO;
				SWIFT_ACTIVE_COMPILATION_CONDITIONS = "WIDGET_EXTENSION $(inherited)";
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = "1,2";
			}};
			name = Release;
		}};
		500000032D50000000000001 /* Debug */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ALWAYS_SEARCH_USER_PATHS = NO;
				BUNDLE_LOADER = "$(TEST_HOST)";
				CLANG_ENABLE_MODULES = YES;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				DEVELOPMENT_TEAM = 58TYVC4N97;
				GENERATE_INFOPLIST_FILE = YES;
				IPHONEOS_DEPLOYMENT_TARGET = 17.0;
				MARKETING_VERSION = 1.0;
				ONLY_ACTIVE_ARCH = YES;
				PRODUCT_BUNDLE_IDENTIFIER = com.hoojinguyen.vocabcraft.tests;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SDKROOT = iphoneos;
				SUPPORTED_PLATFORMS = "iphoneos iphonesimulator";
				SUPPORTS_MACCATALYST = NO;
				SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD = NO;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = "1,2";
				TEST_HOST = "$(BUILT_PRODUCTS_DIR)/VocabCraftApp.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/VocabCraftApp";
			}};
			name = Debug;
		}};
		500000032D50000000000002 /* Release */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ALWAYS_SEARCH_USER_PATHS = NO;
				BUNDLE_LOADER = "$(TEST_HOST)";
				CLANG_ENABLE_MODULES = YES;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				DEVELOPMENT_TEAM = 58TYVC4N97;
				GENERATE_INFOPLIST_FILE = YES;
				IPHONEOS_DEPLOYMENT_TARGET = 17.0;
				MARKETING_VERSION = 1.0;
				ONLY_ACTIVE_ARCH = NO;
				PRODUCT_BUNDLE_IDENTIFIER = com.hoojinguyen.vocabcraft.tests;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SDKROOT = iphoneos;
				SUPPORTED_PLATFORMS = "iphoneos iphonesimulator";
				SUPPORTS_MACCATALYST = NO;
				SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD = NO;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = "1,2";
				TEST_HOST = "$(BUILT_PRODUCTS_DIR)/VocabCraftApp.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/VocabCraftApp";
			}};
			name = Release;
		}};

/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
		500000002D50000000000000 /* Build configuration list for PBXProject "VocabCraftApp" */ = {{
			isa = XCConfigurationList;
			buildConfigurations = (
				500000002D50000000000001 /* Debug */,
				500000002D50000000000002 /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		}};
		500000012D50000000000000 /* Build configuration list for PBXNativeTarget "VocabCraftApp" */ = {{
			isa = XCConfigurationList;
			buildConfigurations = (
				500000012D50000000000001 /* Debug */,
				500000012D50000000000002 /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		}};
		500000022D50000000000000 /* Build configuration list for PBXNativeTarget "VocabCraftWidgetExtension" */ = {{
			isa = XCConfigurationList;
			buildConfigurations = (
				500000022D50000000000001 /* Debug */,
				500000022D50000000000002 /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		}};
		500000032D50000000000000 /* Build configuration list for PBXNativeTarget "VocabCraftAppTests" */ = {{
			isa = XCConfigurationList;
			buildConfigurations = (
				500000032D50000000000001 /* Debug */,
				500000032D50000000000002 /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		}};
/* End XCConfigurationList section */

/* Begin XCLocalSwiftPackageReference section */
		900000000000000000000001 /* XCLocalSwiftPackageReference "CraftUIKit" */ = {{
			isa = XCLocalSwiftPackageReference;
			relativePath = Packages/CraftUIKit;
		}};
		900000000000000000000005 /* XCLocalSwiftPackageReference "SpeechKit" */ = {{
			isa = XCLocalSwiftPackageReference;
			relativePath = Packages/SpeechKit;
		}};
/* End XCLocalSwiftPackageReference section */

/* Begin XCSwiftPackageProductDependency section */
		900000000000000000000002 /* CraftUIKit */ = {{
			isa = XCSwiftPackageProductDependency;
			package = 900000000000000000000001 /* XCLocalSwiftPackageReference "CraftUIKit" */;
			productName = CraftUIKit;
		}};
		900000000000000000000006 /* SpeechKit */ = {{
			isa = XCSwiftPackageProductDependency;
			package = 900000000000000000000005 /* XCLocalSwiftPackageReference "SpeechKit" */;
			productName = SpeechKit;
		}};
/* End XCSwiftPackageProductDependency section */
	}};
	rootObject = 100000002D50000000000000 /* Project object */;
}}
"""
    os.makedirs("VocabCraftApp.xcodeproj", exist_ok=True)
    with open("VocabCraftApp.xcodeproj/project.pbxproj", "w") as f:
        f.write(content)
    print("Dynamically generated complete PBXGroups and Targets in project.pbxproj!")

if __name__ == "__main__":
    generate_pbxproj()
