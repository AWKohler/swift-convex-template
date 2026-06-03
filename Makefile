# ─────────────────────────────────────────────────────────────────
# Makefile — Botflow remote Mac cloud build commands
#
# Typical flow on a remote Mac runner:
#   1. `make generate`  — produce MyApp.xcodeproj from project.yml
#   2. `make build`     — compile for the iOS Simulator
#   3. `make clean`     — wipe generated artefacts between runs
#
# Prerequisites (must be pre-installed on the runner):
#   • Xcode 16+   (xcodebuild)
#   • XcodeGen    (brew install xcodegen)
# ─────────────────────────────────────────────────────────────────

SCHEME      := MyApp
PROJECT     := MyApp.xcodeproj
SDK         := iphonesimulator
# Force SwiftPM to use ONLY the committed Package.resolved + warm cache —
# never fetch/re-resolve over the network during a build. Pairs with the
# pre-warmed controller cache so the hot rebuild loop stays offline & fast.
SPM_FROZEN  := -onlyUsePackageVersionsFromResolvedFile -disableAutomaticPackageResolution
# Use the latest available simulator so the runner doesn't need a
# specific OS version pinned.
DESTINATION := platform=iOS Simulator,name=iPhone 16,OS=latest
BUILD_DIR   := .build

# ── Targets ───────────────────────────────────────────────────────

.PHONY: generate build clean open

## generate: Run XcodeGen to produce $(PROJECT) from project.yml.
##           Re-run after every Botflow file-injection pass.
generate:
	xcodegen generate --spec project.yml
	@# Restore the frozen SwiftPM resolution into the freshly generated
	@# workspace. The .xcodeproj is gitignored/regenerated, so the committed
	@# repo-root Package.resolved is the source of truth. With the controller's
	@# pre-warmed SPM cache this lets `build` resolve ConvexMobile WITHOUT any
	@# network fetch (see project.yml for the full rationale).
	@if [ -f Package.resolved ]; then \
		mkdir -p "$(PROJECT)/project.xcworkspace/xcshareddata/swiftpm" ; \
		cp Package.resolved "$(PROJECT)/project.xcworkspace/xcshareddata/swiftpm/Package.resolved" ; \
		echo "Restored pinned Package.resolved into workspace." ; \
	fi

## build: Compile the app for the iOS Simulator.
##        Implicitly runs `generate` first so the .xcodeproj is
##        always in sync with the current source tree.
build: generate
	xcodebuild \
		-project "$(PROJECT)" \
		-scheme  "$(SCHEME)"  \
		-sdk     "$(SDK)"     \
		-destination "$(DESTINATION)" \
		-derivedDataPath "$(BUILD_DIR)" \
		$(SPM_FROZEN) \
		-parallelizeTargets \
		CODE_SIGN_IDENTITY="" \
		CODE_SIGNING_REQUIRED=NO \
		CODE_SIGNING_ALLOWED=NO \
		build | xcpretty || xcodebuild \
			-project "$(PROJECT)" \
			-scheme  "$(SCHEME)"  \
			-sdk     "$(SDK)"     \
			-destination "$(DESTINATION)" \
			-derivedDataPath "$(BUILD_DIR)" \
			$(SPM_FROZEN) \
			CODE_SIGN_IDENTITY="" \
			CODE_SIGNING_REQUIRED=NO \
			CODE_SIGNING_ALLOWED=NO \
			build

## clean: Remove generated project and build artefacts.
clean:
	rm -rf "$(PROJECT)" "$(BUILD_DIR)"
	@echo "Cleaned $(PROJECT) and $(BUILD_DIR)."

## open: Generate and open the project in Xcode (local dev only).
open: generate
	open "$(PROJECT)"
