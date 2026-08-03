import os

def create_xcodeproj():
    pbxproj_content = """// !$*UTF8*$!
{
	archiveVersion = 1;
	classes = {
	};
	objectVersion = 56;
	objects = {

/* Begin PBXBuildFile section */
		F10000012D50000000000001 /* VocabCraftApp.swift in Sources */ = {isa = PBXBuildFile; fileRef = F10000012D50000000000000 /* VocabCraftApp.swift */; };
		F10000022D50000000000001 /* DatasetEngine.swift in Sources */ = {isa = PBXBuildFile; fileRef = F10000022D50000000000000 /* DatasetEngine.swift */; };
		F10000032D50000000000001 /* DatasetModels.swift in Sources */ = {isa = PBXBuildFile; fileRef = F10000032D50000000000000 /* DatasetModels.swift */; };
		F10000042D50000000000001 /* SharedAppGroupContainer.swift in Sources */ = {isa = PBXBuildFile; fileRef = F10000042D50000000000000 /* SharedAppGroupContainer.swift */; };
		F10000052D50000000000001 /* SwiftDataModels.swift in Sources */ = {isa = PBXBuildFile; fileRef = F10000052D50000000000000 /* SwiftDataModels.swift */; };
		F10000062D50000000000001 /* SpeechRecognitionService.swift in Sources */ = {isa = PBXBuildFile; fileRef = F10000062D50000000000000 /* SpeechRecognitionService.swift */; };
		F10000072D50000000000001 /* TextToSpeechService.swift in Sources */ = {isa = PBXBuildFile; fileRef = F10000072D50000000000000 /* TextToSpeechService.swift */; };
		F10000082D50000000000001 /* SRSEngine.swift in Sources */ = {isa = PBXBuildFile; fileRef = F10000082D50000000000000 /* SRSEngine.swift */; };
		F10000092D50000000000001 /* ReflexDrillView.swift in Sources */ = {isa = PBXBuildFile; fileRef = F10000092D50000000000000 /* ReflexDrillView.swift */; };
/* End PBXBuildFile section */

/* Begin PBXFileReference section */
		F10000002D50000000000000 /* VocabCraftApp.app */ = {isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = VocabCraftApp.app; sourceTree = BUILT_PRODUCTS_DIR; };
		F10000012D50000000000000 /* VocabCraftApp.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = App/VocabCraftApp.swift; sourceTree = "<group>"; };
		F10000022D50000000000000 /* DatasetEngine.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = Core/Database/DatasetEngine.swift; sourceTree = "<group>"; };
		F10000032D50000000000000 /* DatasetModels.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = Core/Database/DatasetModels.swift; sourceTree = "<group>"; };
		F10000042D50000000000000 /* SharedAppGroupContainer.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = Core/Database/SharedAppGroupContainer.swift; sourceTree = "<group>"; };
		F10000052D50000000000000 /* SwiftDataModels.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = Core/Database/SwiftDataModels.swift; sourceTree = "<group>"; };
		F10000062D50000000000000 /* SpeechRecognitionService.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = Core/Audio/SpeechRecognitionService.swift; sourceTree = "<group>"; };
		F10000072D50000000000000 /* TextToSpeechService.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = Core/Audio/TextToSpeechService.swift; sourceTree = "<group>"; };
		F10000082D50000000000000 /* SRSEngine.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = Core/SRS/SRSEngine.swift; sourceTree = "<group>"; };
		F10000092D50000000000000 /* ReflexDrillView.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = Features/ReflexDrill/ReflexDrillView.swift; sourceTree = "<group>"; };
		F10000102D50000000000000 /* Info.plist */ = {isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = App/Info.plist; sourceTree = "<group>"; };
		F10000112D50000000000000 /* VocabCraftApp.entitlements */ = {isa = PBXFileReference; lastKnownFileType = text.plist.entitlements; path = App/VocabCraftApp.entitlements; sourceTree = "<group>"; };
/* End PBXFileReference section */

/* Begin PBXFrameworksBuildPhase section */
		F10000002D50000000000001 /* Frameworks */ = {
			isa = PBXFrameworksBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
/* End PBXFrameworksBuildPhase section */

/* Begin PBXGroup section */
		F10000002D50000000000002 /* MainGroup */ = {
			isa = PBXGroup;
			children = (
				F10000002D50000000000003 /* VocabCraftApp */,
				F10000002D50000000000004 /* Products */,
			);
			sourceTree = "<group>";
		};
		F10000002D50000000000003 /* VocabCraftApp */ = {
			isa = PBXGroup;
			children = (
				F10000012D50000000000000 /* VocabCraftApp.swift */,
				F10000022D50000000000000 /* DatasetEngine.swift */,
				F10000032D50000000000000 /* DatasetModels.swift */,
				F10000042D50000000000000 /* SharedAppGroupContainer.swift */,
				F10000052D50000000000000 /* SwiftDataModels.swift */,
				F10000062D50000000000000 /* SpeechRecognitionService.swift */,
				F10000072D50000000000000 /* TextToSpeechService.swift */,
				F10000082D50000000000000 /* SRSEngine.swift */,
				F10000092D50000000000000 /* ReflexDrillView.swift */,
				F10000102D50000000000000 /* Info.plist */,
				F10000112D50000000000000 /* VocabCraftApp.entitlements */,
			);
			path = VocabCraftApp;
			sourceTree = "<group>";
		};
		F10000002D50000000000004 /* Products */ = {
			isa = PBXGroup;
			children = (
				F10000002D50000000000000 /* VocabCraftApp.app */,
			);
			name = Products;
			sourceTree = "<group>";
		};
/* End PBXGroup section */

/* Begin PBXNativeTarget section */
		F10000002D50000000000005 /* VocabCraftApp */ = {
			isa = PBXNativeTarget;
			buildConfigurationList = F10000002D50000000000006 /* Build configuration list for PBXNativeTarget "VocabCraftApp" */;
			buildPhases = (
				F10000002D50000000000007 /* Sources */,
				F10000002D50000000000001 /* Frameworks */,
			);
			buildRules = (
			);
			dependencies = (
			);
			name = VocabCraftApp;
			productName = VocabCraftApp;
			productReference = F10000002D50000000000000 /* VocabCraftApp.app */;
			productType = "com.apple.product-type.application";
		};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
		F10000002D50000000000008 /* Project object */ = {
			isa = PBXProject;
			attributes = {
				BuildIndependentTargetsInParallel = 1;
				LastSwiftUpdateCheck = 1540;
				LastUpgradeCheck = 1540;
				TargetAttributes = {
					F10000002D50000000000005 = {
						CreatedOnToolsVersion = 15.4;
					};
				};
			};
			buildConfigurationList = F10000002D50000000000009 /* Build configuration list for PBXProject "VocabCraftApp" */;
			compatibilityVersion = "Xcode 14.0";
			developmentRegion = en;
			hasScannedForEncodings = 0;
			knownRegions = (
				en,
				Base,
			);
			mainGroup = F10000002D50000000000002 /* MainGroup */;
			productRefGroup = F10000002D50000000000004 /* Products */;
			projectDirPath = "";
			projectRoot = "";
			targets = (
				F10000002D50000000000005 /* VocabCraftApp */,
			);
		};
/* End PBXProject section */

/* Begin PBXSourcesBuildPhase section */
		F10000002D50000000000007 /* Sources */ = {
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
				F10000012D50000000000001 /* VocabCraftApp.swift in Sources */,
				F10000022D50000000000001 /* DatasetEngine.swift in Sources */,
				F10000032D50000000000001 /* DatasetModels.swift in Sources */,
				F10000042D50000000000001 /* SharedAppGroupContainer.swift in Sources */,
				F10000052D50000000000001 /* SwiftDataModels.swift in Sources */,
				F10000062D50000000000001 /* SpeechRecognitionService.swift in Sources */,
				F10000072D50000000000001 /* TextToSpeechService.swift in Sources */,
				F10000082D50000000000001 /* SRSEngine.swift in Sources */,
				F10000092D50000000000001 /* ReflexDrillView.swift in Sources */,
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
/* End PBXSourcesBuildPhase section */

/* Begin XCBuildConfiguration section */
		F10000002D50000000000010 /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ALWAYS_SEARCH_USER_PATHS = NO;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				GENERATE_INFOPLIST_FILE = NO;
				INFOPLIST_FILE = VocabCraftApp/App/Info.plist;
				IPHONEOS_DEPLOYMENT_TARGET = 17.0;
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.hoojinguyen.vocabcraft;
				PRODUCT_NAME = "$(TARGET_NAME)";
				CODE_SIGN_ENTITLEMENTS = VocabCraftApp/App/VocabCraftApp.entitlements;
				SDKROOT = iphoneos;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = "1,2";
			};
			name = Debug;
		};
		F10000002D50000000000011 /* Release */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ALWAYS_SEARCH_USER_PATHS = NO;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				GENERATE_INFOPLIST_FILE = NO;
				INFOPLIST_FILE = VocabCraftApp/App/Info.plist;
				IPHONEOS_DEPLOYMENT_TARGET = 17.0;
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.hoojinguyen.vocabcraft;
				PRODUCT_NAME = "$(TARGET_NAME)";
				CODE_SIGN_ENTITLEMENTS = VocabCraftApp/App/VocabCraftApp.entitlements;
				SDKROOT = iphoneos;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = "1,2";
			};
			name = Release;
		};
		F10000002D50000000000012 /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ALWAYS_SEARCH_USER_PATHS = NO;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				GENERATE_INFOPLIST_FILE = NO;
				INFOPLIST_FILE = VocabCraftApp/App/Info.plist;
				IPHONEOS_DEPLOYMENT_TARGET = 17.0;
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.hoojinguyen.vocabcraft;
				PRODUCT_NAME = "$(TARGET_NAME)";
				CODE_SIGN_ENTITLEMENTS = VocabCraftApp/App/VocabCraftApp.entitlements;
				SDKROOT = iphoneos;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = "1,2";
			};
			name = Debug;
		};
		F10000002D50000000000013 /* Release */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ALWAYS_SEARCH_USER_PATHS = NO;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				GENERATE_INFOPLIST_FILE = NO;
				INFOPLIST_FILE = VocabCraftApp/App/Info.plist;
				IPHONEOS_DEPLOYMENT_TARGET = 17.0;
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.hoojinguyen.vocabcraft;
				PRODUCT_NAME = "$(TARGET_NAME)";
				CODE_SIGN_ENTITLEMENTS = VocabCraftApp/App/VocabCraftApp.entitlements;
				SDKROOT = iphoneos;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = "1,2";
			};
			name = Release;
		};
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
		F10000002D50000000000006 /* Build configuration list for PBXNativeTarget "VocabCraftApp" */ = {
			isa = XCConfigurationList;
			buildConfigurations = (
				F10000002D50000000000012 /* Debug */,
				F10000002D50000000000013 /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		};
		F10000002D50000000000009 /* Build configuration list for PBXProject "VocabCraftApp" */ = {
			isa = XCConfigurationList;
			buildConfigurations = (
				F10000002D50000000000010 /* Debug */,
				F10000002D50000000000011 /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		};
/* End XCConfigurationList section */
	};
	rootObject = F10000002D50000000000008 /* Project object */;
}
"""
    os.makedirs("VocabCraftApp.xcodeproj", exist_ok=True)
    with open("VocabCraftApp.xcodeproj/project.pbxproj", "w") as f:
        f.write(pbxproj_content)
    print("VocabCraftApp.xcodeproj updated successfully!")

if __name__ == "__main__":
    create_xcodeproj()
