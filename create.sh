#!/usr/bin/env bash
# ============================================================
#  BleNdEr Client — Project Scaffold Generator
#  Author: MiK_SSER
#  Target: Fabric 1.21.11 / Java 21
#
#  Usage:
#    chmod +x create-blender-client.sh
#    ./create-blender-client.sh
#    cd blender-client && gradle wrapper && ./gradlew build
# ============================================================

set -euo pipefail

ROOT="blender-client"
PKG_DIR="src/main/java/com/mik_sser/blenderclient"
MIXIN_DIR="${PKG_DIR}/mixin"
RES_DIR="src/main/resources"
ASSETS_DIR="${RES_DIR}/assets/blender-client"

echo ">>> Creating directory tree..."
mkdir -p "${ROOT}/${MIXIN_DIR}"
mkdir -p "${ROOT}/${ASSETS_DIR}/lang"

cd "${ROOT}"

# ------------------------------------------------------------
#  build.gradle
# ------------------------------------------------------------
echo ">>> Writing build.gradle"
cat > build.gradle << 'EOF'
plugins {
    id 'fabric-loom' version "${loom_version}"
    id 'maven-publish'
}

version = project.mod_version
group = project.maven_group

base {
    archivesName = project.archives_base_name
}

repositories {
    mavenCentral()
}

dependencies {
    minecraft "com.mojang:minecraft:${project.minecraft_version}"
    mappings "net.fabricmc:yarn:${project.yarn_mappings}:v2"
    modImplementation "net.fabricmc:fabric-loader:${project.loader_version}"
    modImplementation "net.fabricmc.fabric-api:fabric-api:${project.fabric_api_version}"
}

processResources {
    inputs.property "version", project.version
    filesMatching("fabric.mod.json") {
        expand "version": project.version
    }
}

tasks.withType(JavaCompile).configureEach {
    it.options.release = 21
}

java {
    withSourcesJar()
    sourceCompatibility = JavaVersion.VERSION_21
    targetCompatibility = JavaVersion.VERSION_21
}
EOF

# ------------------------------------------------------------
#  gradle.properties
# ------------------------------------------------------------
echo ">>> Writing gradle.properties"
cat > gradle.properties << 'EOF'
# Memory for Gradle
org.gradle.jvmargs=-Xmx2G
org.gradle.parallel=true

# Fabric / Minecraft 1.21.1 versions
minecraft_version=1.21.1
yarn_mappings=1.21.1+build.3
loader_version=0.16.9
fabric_api_version=0.116.5+1.21.1
loom_version=1.9.2

# Mod metadata
mod_version=1.0.0
maven_group=com.mik_sser.blenderclient
archives_base_name=blender-client
EOF

# ------------------------------------------------------------
#  settings.gradle
# ------------------------------------------------------------
echo ">>> Writing settings.gradle"
cat > settings.gradle << 'EOF'
pluginManagement {
    repositories {
        maven { name = 'Fabric'; url = 'https://maven.fabricmc.net/' }
        mavenCentral()
        gradlePluginPortal()
    }
}

rootProject.name = 'blender-client'
EOF

# ------------------------------------------------------------
#  src/main/java/.../BlenderClient.java
# ------------------------------------------------------------
echo ">>> Writing BlenderClient.java"
cat > "${PKG_DIR}/BlenderClient.java" << 'EOF'
package com.mik_sser.blenderclient;

import net.fabricmc.api.ClientModInitializer;
import net.fabricmc.api.EnvType;
import net.fabricmc.api.Environment;
import net.fabricmc.fabric.api.client.event.lifecycle.v1.ClientTickEvents;
import net.fabricmc.fabric.api.client.keybinding.v1.KeyBindingHelper;
import net.minecraft.client.option.KeyBinding;
import net.minecraft.client.util.InputUtil;
import org.lwjgl.glfw.GLFW;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@Environment(EnvType.CLIENT)
public class BlenderClient implements ClientModInitializer {
    public static final String MOD_ID = "blender-client";
    public static final Logger LOGGER = LoggerFactory.getLogger(MOD_ID);

    // Right Shift opens the menu
    public static KeyBinding menuKey;

    @Override
    public void onInitializeClient() {
        LOGGER.info("BleNdEr Client by MiK_SSER loaded.");

        menuKey = KeyBindingHelper.registerKeyBinding(new KeyBinding(
                "key.blender-client.menu",
                InputUtil.Type.KEYSYM,
                GLFW.GLFW_KEY_RIGHT_SHIFT,
                "category.blender-client"
        ));

        ClientTickEvents.END_CLIENT_TICK.register(client -> {
            while (menuKey.wasPressed()) {
                if (client.currentScreen == null) {
                    client.setScreen(new BlenderMenuScreen());
                }
            }
        });

        BlenderHudRenderer.register();
    }
}
EOF

# ------------------------------------------------------------
#  src/main/java/.../BlenderMenuScreen.java
# ------------------------------------------------------------
echo ">>> Writing BlenderMenuScreen.java"
cat > "${PKG_DIR}/BlenderMenuScreen.java" << 'EOF'
package com.mik_sser.blenderclient;

import net.fabricmc.api.EnvType;
import net.fabricmc.api.Environment;
import net.minecraft.client.gui.DrawContext;
import net.minecraft.client.gui.screen.Screen;
import net.minecraft.text.Text;

@Environment(EnvType.CLIENT)
public class BlenderMenuScreen extends Screen {
    private static final int BG_COLOR     = 0xFF0A0A0A; // #0A0A0A
    private static final int ACCENT_COLOR = 0xFF00FFFF; // Neon Cyan

    private int panelX, panelY, panelWidth, panelHeight;

    public BlenderMenuScreen() {
        super(Text.literal("BleNdEr Client"));
    }

    @Override
    protected void init() {
        panelWidth  = 300;
        panelHeight = 200;
        panelX = (width  - panelWidth)  / 2;
        panelY = (height - panelHeight) / 2;

        // Placeholder for category buttons; wire up as you add modules
        // addDrawableChild(new RoundedButton(panelX + 20, panelY + 40, 120, 20,
        //         Text.literal("Visuals"), b -> { /* open submenu */ }));
    }

    @Override
    public void render(DrawContext context, int mouseX, int mouseY, float delta) {
        renderBackground(context, mouseX, mouseY, delta);

        RoundedRectRenderer.drawRoundedRect(
                context, panelX, panelY, panelWidth, panelHeight,
                12.0f, BG_COLOR, ACCENT_COLOR, 2.0f
        );

        context.drawTextWithShadow(textRenderer, "BleNdEr Client",
                panelX + 20, panelY + 15, ACCENT_COLOR);

        super.render(context, mouseX, mouseY, delta);
    }

    @Override
    public boolean shouldPause() {
        return false;
    }
}
EOF

# ------------------------------------------------------------
#  src/main/java/.../RoundedRectRenderer.java
# ------------------------------------------------------------
echo ">>> Writing RoundedRectRenderer.java"
cat > "${PKG_DIR}/RoundedRectRenderer.java" << 'EOF'
package com.mik_sser.blenderclient;

import net.fabricmc.api.EnvType;
import net.fabricmc.api.Environment;
import net.minecraft.client.gui.DrawContext;

/**
 * Placeholder rounded-rect renderer.
 * For production, use Brapi (bRender.roundRect) or a custom SDF shader
 * to obtain true anti-aliased corners. This stub falls back to a plain fill.
 */
@Environment(EnvType.CLIENT)
public final class RoundedRectRenderer {

    public static void drawRoundedRect(DrawContext context,
                                       float x, float y, float width, float height,
                                       float radius,
                                       int fillColor, int borderColor, float borderWidth) {
        // Fallback: sharp rectangle. Replace with a shader or Brapi call.
        int xi = (int) x, yi = (int) y;
        int wi = (int) width, hi = (int) height;
        context.fill(xi, yi, xi + wi, yi + hi, fillColor);

        // Simple border
        int bw = (int) borderWidth;
        context.fill(xi, yi, xi + wi, yi + bw, borderColor);
        context.fill(xi, yi + hi - bw, xi + wi, yi + hi, borderColor);
        context.fill(xi, yi, xi + bw, yi + hi, borderColor);
        context.fill(xi + wi - bw, yi, xi + wi, yi + hi, borderColor);
    }

    private RoundedRectRenderer() {}
}
EOF

# ------------------------------------------------------------
#  src/main/java/.../ClickTracker.java
# ------------------------------------------------------------
echo ">>> Writing ClickTracker.java"
cat > "${PKG_DIR}/ClickTracker.java" << 'EOF'
package com.mik_sser.blenderclient;

import net.fabricmc.api.EnvType;
import net.fabricmc.api.Environment;

import java.util.ArrayDeque;
import java.util.Deque;

@Environment(EnvType.CLIENT)
public final class ClickTracker {
    private static final Deque<Long> LEFT_CLICKS  = new ArrayDeque<>();
    private static final Deque<Long> RIGHT_CLICKS = new ArrayDeque<>();
    private static final long WINDOW_MS = 1000L;

    public static void onLeftClick()  { push(LEFT_CLICKS); }
    public static void onRightClick() { push(RIGHT_CLICKS); }

    private static void push(Deque<Long> queue) {
        long now = System.currentTimeMillis();
        queue.addLast(now);
        while (!queue.isEmpty() && now - queue.peekFirst() > WINDOW_MS) {
            queue.pollFirst();
        }
    }

    public static int getCps()      { return Math.max(LEFT_CLICKS.size(), RIGHT_CLICKS.size()); }
    public static int getLeftCps()  { return LEFT_CLICKS.size();  }
    public static int getRightCps() { return RIGHT_CLICKS.size(); }

    private ClickTracker() {}
}
EOF

# ------------------------------------------------------------
#  src/main/java/.../BlenderHudRenderer.java
# ------------------------------------------------------------
echo ">>> Writing BlenderHudRenderer.java"
cat > "${PKG_DIR}/BlenderHudRenderer.java" << 'EOF'
package com.mik_sser.blenderclient;

import net.fabricmc.api.EnvType;
import net.fabricmc.api.Environment;
import net.fabricmc.fabric.api.client.rendering.v1.HudRenderCallback;
import net.minecraft.client.MinecraftClient;
import net.minecraft.client.gui.DrawContext;
import net.minecraft.item.ItemStack;
import net.minecraft.util.math.MathHelper;

import java.time.LocalTime;
import java.time.format.DateTimeFormatter;

@Environment(EnvType.CLIENT)
public class BlenderHudRenderer {
    private static final MinecraftClient mc = MinecraftClient.getInstance();
    private static final DateTimeFormatter TIME_FORMAT = DateTimeFormatter.ofPattern("HH:mm:ss");

    // Toggles (later: move to a JSON config)
    public static boolean showWatermark = true;
    public static boolean showArmor     = true;
    public static boolean showKeystrokes= true;
    public static boolean showCps       = true;
    public static boolean showCoords    = true;
    public static boolean showDirection = true;
    public static boolean showMemory    = true;

    public static void register() {
        HudRenderCallback.EVENT.register((drawContext, tickDelta) -> {
            if (mc.player == null || mc.world == null) return;
            renderAll(drawContext);
        });
    }

    private static void renderAll(DrawContext ctx) {
        int w = mc.getWindow().getScaledWidth();
        int h = mc.getWindow().getScaledHeight();

        if (showWatermark)  renderWatermark(ctx, 5, 5);
        if (showArmor)      renderArmor(ctx, w - 20, h / 2 - 40);
        if (showKeystrokes) renderKeystrokes(ctx, 5, h - 80);
        if (showCps)        renderCps(ctx, 5, h - 100);
        if (showCoords)     renderCoords(ctx, 5, h - 60);
        if (showDirection)  renderDirection(ctx, 5, h - 40);
        if (showMemory)     renderMemory(ctx, w - 110, 5);
    }

    private static void renderWatermark(DrawContext ctx, int x, int y) {
        String fps  = mc.getCurrentFps() + " FPS";
        String ping = getPing() + " ms";
        String time = LocalTime.now().format(TIME_FORMAT);
        String text = "BleNdEr Client | " + fps + " | " + ping + " | " + time;

        float hue = (System.currentTimeMillis() % 5000) / 5000.0f;
        int color = MathHelper.hsvToRgb(hue, 1.0f, 1.0f) | 0xFF000000;
        ctx.drawTextWithShadow(mc.textRenderer, text, x, y, color);
    }

    private static int getPing() {
        if (mc.getNetworkHandler() != null && mc.player != null) {
            var entry = mc.getNetworkHandler().getPlayerListEntry(mc.player.getUuid());
            if (entry != null) return entry.getLatency();
        }
        return 0;
    }

    private static void renderArmor(DrawContext ctx, int x, int y) {
        var armor = mc.player.getInventory().armor;
        for (int i = 0; i < armor.size(); i++) {
            ItemStack stack = armor.get(i);
            if (stack.isEmpty()) continue;
            int offsetY = y + (3 - i) * 20;
            ctx.drawItem(stack, x, offsetY);
            ctx.drawItemInSlot(mc.textRenderer, stack, x, offsetY);
        }
    }

    private static void renderKeystrokes(DrawContext ctx, int x, int y) {
        drawKey(ctx, x + 22, y,      "W", mc.options.forwardKey.isPressed());
        drawKey(ctx, x,      y + 22, "A", mc.options.leftKey.isPressed());
        drawKey(ctx, x + 22, y + 22, "S", mc.options.backKey.isPressed());
        drawKey(ctx, x + 44, y + 22, "D", mc.options.rightKey.isPressed());
    }

    private static void drawKey(DrawContext ctx, int x, int y, String label, boolean pressed) {
        int bg = pressed ? 0xFF00FFFF : 0xFF333333;
        ctx.fill(x, y, x + 20, y + 20, bg);
        ctx.drawTextWithShadow(mc.textRenderer, label, x + 6, y + 6, 0xFFFFFFFF);
    }

    private static void renderCps(DrawContext ctx, int x, int y) {
        int cps = ClickTracker.getCps();
        ctx.drawTextWithShadow(mc.textRenderer, "CPS: " + cps, x, y, 0xFF00FFFF);
    }

    private static void renderCoords(DrawContext ctx, int x, int y) {
        var pos = mc.player.getBlockPos();
        String text = String.format("XYZ: %d, %d, %d", pos.getX(), pos.getY(), pos.getZ());
        ctx.drawTextWithShadow(mc.textRenderer, text, x, y, 0xFFFFFFFF);
    }

    private static void renderDirection(DrawContext ctx, int x, int y) {
        String dir = mc.player.getHorizontalFacing().asString().toUpperCase();
        ctx.drawTextWithShadow(mc.textRenderer, "Facing: " + dir, x, y, 0xFFFFFFFF);
    }

    private static void renderMemory(DrawContext ctx, int x, int y) {
        Runtime rt = Runtime.getRuntime();
        long used = (rt.totalMemory() - rt.freeMemory()) / 1024 / 1024;
        long max  = rt.maxMemory() / 1024 / 1024;
        String text = "RAM: " + used + " / " + max + " MB";
        ctx.drawTextWithShadow(mc.textRenderer, text, x, y, 0xFFAAAAAA);
    }
}
EOF

# ------------------------------------------------------------
#  src/main/java/.../mixin/GameRendererMixin.java
# ------------------------------------------------------------
echo ">>> Writing mixin/GameRendererMixin.java"
cat > "${PKG_DIR}/mixin/GameRendererMixin.java" << 'EOF'
package com.mik_sser.blenderclient.mixin;

import net.minecraft.client.render.Camera;
import net.minecraft.client.render.GameRenderer;
import net.minecraft.util.math.MathHelper;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfoReturnable;

@Mixin(GameRenderer.class)
public class GameRendererMixin {

    @Inject(method = "getFov", at = @At("RETURN"), cancellable = true)
    private void onGetFov(Camera camera, float tickDelta, boolean changingFov,
                          CallbackInfoReturnable<Float> cir) {
        if (changingFov) {
            float originalFov = cir.getReturnValue();
            float zoomedFov   = originalFov * 0.5f;
            cir.setReturnValue(MathHelper.lerp(0.5f, originalFov, zoomedFov));
        }
    }
}
EOF

# ------------------------------------------------------------
#  src/main/java/.../mixin/MouseMixin.java
# ------------------------------------------------------------
echo ">>> Writing mixin/MouseMixin.java"
cat > "${PKG_DIR}/mixin/MouseMixin.java" << 'EOF'
package com.mik_sser.blenderclient.mixin;

import com.mik_sser.blenderclient.ClickTracker;
import net.minecraft.client.Mouse;
import org.lwjgl.glfw.GLFW;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;

@Mixin(Mouse.class)
public class MouseMixin {

    private static boolean isDraggingSlider = false;

    @Inject(method = "onMouseScroll", at = @At("HEAD"), cancellable = true)
    private void onScroll(long window, double horizontal, double vertical, CallbackInfo ci) {
        if (isDraggingSlider) {
            ci.cancel();
        }
    }

    @Inject(method = "onMouseButton", at = @At("HEAD"))
    private void onMouseButton(long window, int button, int action, int mods, CallbackInfo ci) {
        if (action == GLFW.GLFW_PRESS) {
            if (button == GLFW.GLFW_MOUSE_BUTTON_LEFT)  ClickTracker.onLeftClick();
            if (button == GLFW.GLFW_MOUSE_BUTTON_RIGHT) ClickTracker.onRightClick();
        }
    }

    public static void setDraggingSlider(boolean dragging) {
        isDraggingSlider = dragging;
    }
}
EOF

# ------------------------------------------------------------
#  src/main/java/.../mixin/LightmapTextureManagerMixin.java
# ------------------------------------------------------------
echo ">>> Writing mixin/LightmapTextureManagerMixin.java"
cat > "${PKG_DIR}/mixin/LightmapTextureManagerMixin.java" << 'EOF'
package com.mik_sser.blenderclient.mixin;

import net.minecraft.client.render.LightmapTextureManager;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfoReturnable;

@Mixin(LightmapTextureManager.class)
public class LightmapTextureManagerMixin {

    @Inject(method = "getBrightness", at = @At("RETURN"), cancellable = true)
    private static void forceFullbright(CallbackInfoReturnable<Float> cir) {
        cir.setReturnValue(1.0f);
    }
}
EOF

# ------------------------------------------------------------
#  src/main/java/.../mixin/BackgroundRendererMixin.java
# ------------------------------------------------------------
echo ">>> Writing mixin/BackgroundRendererMixin.java"
cat > "${PKG_DIR}/mixin/BackgroundRendererMixin.java" << 'EOF'
package com.mik_sser.blenderclient.mixin;

import net.minecraft.client.render.BackgroundRenderer;
import net.minecraft.client.render.Camera;
import net.minecraft.client.render.Fog;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfoReturnable;

@Mixin(BackgroundRenderer.class)
public class BackgroundRendererMixin {

    @Inject(method = "applyFog", at = @At("HEAD"), cancellable = true)
    private static void disableFog(Camera camera,
                                   BackgroundRenderer.FogType fogType,
                                   float viewDistance, boolean thickFog,
                                   float tickDelta,
                                   CallbackInfoReturnable<Fog> cir) {
        cir.setReturnValue(new Fog(0.0f, Float.MAX_VALUE, false));
    }
}
EOF

# ------------------------------------------------------------
#  src/main/java/.../mixin/HeldItemRendererMixin.java
# ------------------------------------------------------------
echo ">>> Writing mixin/HeldItemRendererMixin.java"
cat > "${PKG_DIR}/mixin/HeldItemRendererMixin.java" << 'EOF'
package com.mik_sser.blenderclient.mixin;

import net.minecraft.client.render.item.HeldItemRenderer;
import net.minecraft.client.util.math.MatrixStack;
import net.minecraft.entity.LivingEntity;
import net.minecraft.item.ItemStack;
import net.minecraft.item.SwordItem;
import net.minecraft.util.Hand;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;

@Mixin(HeldItemRenderer.class)
public class HeldItemRendererMixin {

    @Inject(method = "renderFirstPersonItem", at = @At("HEAD"))
    private void applyOldBlockingAnimation(LivingEntity entity, float tickDelta, float pitch,
                                           Hand hand, float swingProgress, ItemStack item,
                                           float equipProgress, MatrixStack matrices,
                                           CallbackInfo ci) {
        // 1.8 sword-blocking visual. Customise matrices as needed.
        if (item.getItem() instanceof SwordItem && entity.isBlocking()) {
            // matrices.translate(0.0, -0.1, 0.0);
            // matrices.multiply(RotationAxis.POSITIVE_X.rotationDegrees(-10));
        }
    }
}
EOF

# ------------------------------------------------------------
#  src/main/java/.../mixin/ItemRendererMixin.java
# ------------------------------------------------------------
echo ">>> Writing mixin/ItemRendererMixin.java"
cat > "${PKG_DIR}/mixin/ItemRendererMixin.java" << 'EOF'
package com.mik_sser.blenderclient.mixin;

import net.minecraft.client.render.VertexConsumerProvider;
import net.minecraft.client.render.item.ItemRenderer;
import net.minecraft.client.render.model.json.ModelTransformationMode;
import net.minecraft.client.util.math.MatrixStack;
import net.minecraft.entity.LivingEntity;
import net.minecraft.item.ItemStack;
import net.minecraft.item.Items;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;

@Mixin(ItemRenderer.class)
public class ItemRendererMixin {

    @Inject(method = "renderItem", at = @At("TAIL"))
    private void renderAppleCounter(LivingEntity entity, ItemStack item,
                                    ModelTransformationMode mode, boolean leftHanded,
                                    MatrixStack matrices, VertexConsumerProvider vertexConsumers,
                                    int light, CallbackInfo ci) {
        // Hook point for a 3D apple counter.
        // Extend with TextRenderer + vertexConsumers to draw "xN" beside the stack.
        if (item.isOf(Items.APPLE)) {
            int count = item.getCount();
            if (count > 1) {
                // TODO: draw text
            }
        }
    }
}
EOF

# ------------------------------------------------------------
#  src/main/resources/fabric.mod.json
# ------------------------------------------------------------
echo ">>> Writing fabric.mod.json"
cat > "${RES_DIR}/fabric.mod.json" << 'EOF'
{
  "schemaVersion": 1,
  "id": "blender-client",
  "version": "${version}",
  "name": "BleNdEr Client",
  "description": "Client-side visual QoL and HUD mod.",
  "authors": ["MiK_SSER"],
  "contact": {},
  "license": "MIT",
  "environment": "client",
  "icon": "assets/blender-client/icon.png",
  "entrypoints": {
    "client": [
      "com.mik_sser.blenderclient.BlenderClient"
    ]
  },
  "mixins": [
    "blender-client.mixins.json"
  ],
  "depends": {
    "fabricloader": ">=0.19.3",
    "minecraft": "~1.21.11",
    "java": ">=21",
    "fabric-api": "*"
  }
}
EOF

# ------------------------------------------------------------
#  src/main/resources/blender-client.mixins.json
# ------------------------------------------------------------
echo ">>> Writing blender-client.mixins.json"
cat > "${RES_DIR}/blender-client.mixins.json" << 'EOF'
{
  "required": true,
  "minVersion": "0.8",
  "package": "com.mik_sser.blenderclient.mixin",
  "compatibilityLevel": "JAVA_21",
  "client": [
    "GameRendererMixin",
    "MouseMixin",
    "LightmapTextureManagerMixin",
    "BackgroundRendererMixin",
    "HeldItemRendererMixin",
    "ItemRendererMixin"
  ],
  "injectors": {
    "defaultRequire": 1
  }
}
EOF

# ------------------------------------------------------------
#  Language files
# ------------------------------------------------------------
echo ">>> Writing lang/en_us.json"
cat > "${ASSETS_DIR}/lang/en_us.json" << 'EOF'
{
  "key.blender-client.menu": "Open BleNdEr Menu",
  "category.blender-client": "BleNdEr Client"
}
EOF

echo ">>> Writing lang/ru_ru.json"
cat > "${ASSETS_DIR}/lang/ru_ru.json" << 'EOF'
{
  "key.blender-client.menu": "Открыть меню BleNdEr",
  "category.blender-client": "BleNdEr Client"
}
EOF

# ------------------------------------------------------------
#  Placeholder icon.png (1x1 valid PNG – replace with a real icon)
# ------------------------------------------------------------
echo ">>> Writing placeholder icon.png"
if command -v openssl >/dev/null 2>&1; then
    printf 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==' \
        | openssl base64 -d -A > "${ASSETS_DIR}/icon.png"
else
    echo "WARNING: openssl not found – skipping icon.png. Add a 128x128 PNG manually." >&2
fi

# ------------------------------------------------------------
#  .gitignore
# ------------------------------------------------------------
echo ">>> Writing .gitignore"
cat > .gitignore << 'EOF'
.gradle/
build/
run/
out/
.idea/
*.iml
*.log
EOF

# ------------------------------------------------------------
#  Done
# ------------------------------------------------------------
cd ..

echo ""
echo "============================================================"
echo "  BleNdEr Client scaffold created at: ./${ROOT}/"
echo "============================================================"
echo ""
echo "Next steps:"
echo "  1)  cd ${ROOT}"
echo "  2)  gradle wrapper --gradle-version 8.10"
echo "  3)  ./gradlew genSources        # to inspect mappings"
echo "  4)  ./gradlew build             # jar → build/libs/"
echo ""
echo "Notes:"
echo "  • Yarn signatures for 1.21.11 may differ from the stubs –"
echo "    run 'genSources' and adjust mixin target methods as needed."
echo "  • RoundedRectRenderer is a fallback. For true anti-aliased"
echo "    corners, add Brapi:  modImplementation \"maven.modrinth:brapi:0.25.3+1.21.11+fabric\""
echo "  • Replace assets/blender-client/icon.png with a real 128x128 image."
echo ""
