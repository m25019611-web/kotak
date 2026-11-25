#!/usr/bin/env bash

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

cat > gradle.properties << 'EOF'
org.gradle.jvmargs=-Xmx2G
org.gradle.parallel=true

minecraft_version=1.21.1
yarn_mappings=1.21.1+build.3
loader_version=0.16.9
fabric_api_version=0.116.5+1.21.1
loom_version=1.9.2

mod_version=1.0.0
maven_group=com.mik_sser.blenderclient
archives_base_name=blender-client
EOF

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

@Environment(EnvType.CLIENT)
public class BlenderClient implements ClientModInitializer {
    public static KeyBinding menuKey;

    @Override
    public void onInitializeClient() {
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

cat > "${PKG_DIR}/BlenderMenuScreen.java" << 'EOF'
package com.mik_sser.blenderclient;

import net.fabricmc.api.EnvType;
import net.fabricmc.api.Environment;
import net.minecraft.client.gui.DrawContext;
import net.minecraft.client.gui.screen.Screen;
import net.minecraft.text.Text;

@Environment(EnvType.CLIENT)
public class BlenderMenuScreen extends Screen {
    private static final int BG_COLOR     = 0xFF0A0A0A; 
    private static final int ACCENT_COLOR = 0xFF00FFFF; 

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
    }

    @Override
    public void render(DrawContext context, int mouseX, int mouseY, float delta) {
        renderBackground(context, mouseX, mouseY, delta);

        RoundedRectRenderer.drawRoundedRect(
                context, panelX, panelY, panelWidth, panelHeight,
                12.0f, BG_COLOR, ACCENT_COLOR, 2.0f
        );

        context.drawTextWithShadow(textRenderer, "BleNdEr Client", panelX + 20, panelY + 15, ACCENT_COLOR);
        super.render(context, mouseX, mouseY, delta);
    }

    @Override
    public boolean shouldPause() {
        return false;
    }
}
EOF

cat > "${PKG_DIR}/RoundedRectRenderer.java" << 'EOF'
package com.mik_sser.blenderclient;

import net.fabricmc.api.EnvType;
import net.fabricmc.api.Environment;
import net.minecraft.client.gui.DrawContext;

@Environment(EnvType.CLIENT)
public final class RoundedRectRenderer {
    public static void drawRoundedRect(DrawContext context, float x, float y, float width, float height, float radius, int fillColor, int borderColor, float borderWidth) {
        int xi = (int) x, yi = (int) y;
        int wi = (int) width, hi = (int) height;
        context.fill(xi, yi, xi + wi, yi + hi, fillColor);
        int bw = (int) borderWidth;
        context.fill(xi, yi, xi + wi, yi + bw, borderColor);
        context.fill(xi, yi + hi - bw, xi + wi, yi + hi, borderColor);
        context.fill(xi, yi, xi + bw, yi + hi, borderColor);
        context.fill(xi + wi - bw, yi, xi + wi, yi + hi, borderColor);
    }
    private RoundedRectRenderer() {}
}
EOF

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
    public static int getCps() { return Math.max(LEFT_CLICKS.size(), RIGHT_CLICKS.size()); }
    private ClickTracker() {}
}
EOF

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

    public static void register() {
        HudRenderCallback.EVENT.register((drawContext, tickDelta) -> {
            if (mc.player == null || mc.world == null) return;
            renderAll(drawContext);
        });
    }

    private static void renderAll(DrawContext ctx) {
        int w = mc.getWindow().getScaledWidth();
        int h = mc.getWindow().getScaledHeight();

        renderWatermark(ctx, 5, 5);
        renderArmor(ctx, w - 20, h / 2 - 40);
        renderKeystrokes(ctx, 5, h - 80);
        renderCps(ctx, 5, h - 100);
        renderCoords(ctx, 5, h - 60);
    }

    private static void renderWatermark(DrawContext ctx, int x, int y) {
        String fps  = mc.getCurrentFps() + " FPS";
        String time = LocalTime.now().format(TIME_FORMAT);
        String text = "BleNdEr Client | " + fps + " | " + time;
        float hue = (System.currentTimeMillis() % 5000) / 5000.0f;
        int color = MathHelper.hsvToRgb(hue, 1.0f, 1.0f) | 0xFF000000;
        ctx.drawTextWithShadow(mc.textRenderer, text, x, y, color);
    }

    private static void renderArmor(DrawContext ctx, int x, int y) {
        var armor = mc.player.getInventory().armor;
        for (int i = 0; i < armor.size(); i++) {
            ItemStack stack = armor.get(i);
            if (stack.isEmpty()) continue;
            int offsetY = y + (3 - i) * 20;
            ctx.drawItem(stack, x, offsetY);
        }
    }

    private static void renderKeystrokes(DrawContext ctx, int x, int y) {
        drawKey(ctx, x + 22, y, "W", mc.options.forwardKey.isPressed());
        drawKey(ctx, x, y + 22, "A", mc.options.leftKey.isPressed());
        drawKey(ctx, x + 22, y + 22, "S", mc.options.backKey.isPressed());
        drawKey(ctx, x + 44, y + 22, "D", mc.options.rightKey.isPressed());
    }

    private static void drawKey(DrawContext ctx, int x, int y, String label, boolean pressed) {
        int bg = pressed ? 0xFF00FFFF : 0xFF333333;
        ctx.fill(x, y, x + 20, y + 20, bg);
        ctx.drawTextWithShadow(mc.textRenderer, label, x + 6, y + 6, 0xFFFFFFFF);
    }

    private static void renderCps(DrawContext ctx, int x, int y) {
        ctx.drawTextWithShadow(mc.textRenderer, "CPS: " + ClickTracker.getCps(), x, y, 0xFF00FFFF);
    }

    private static void renderCoords(DrawContext ctx, int x, int y) {
        var pos = mc.player.getBlockPos();
        ctx.drawTextWithShadow(mc.textRenderer, String.format("XYZ: %d, %d, %d", pos.getX(), pos.getY(), pos.getZ()), x, y, 0xFFFFFFFF);
    }
}
EOF

cat > "${PKG_DIR}/mixin/GameRendererMixin.java" << 'EOF'
package com.mik_sser.blenderclient.mixin;

import net.minecraft.client.render.GameRenderer;
import net.minecraft.util.math.MathHelper;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfoReturnable;

@Mixin(GameRenderer.class)
public class GameRendererMixin {
    @Inject(method = "getFov", at = @At("RETURN"), cancellable = true)
    private void onGetFov(net.minecraft.client.render.Camera camera, float tickDelta, boolean changingFov, CallbackInfoReturnable<Float> cir) {
        if (changingFov) {
            float originalFov = cir.getReturnValue();
            cir.setReturnValue(MathHelper.lerp(0.5f, originalFov, originalFov * 0.5f));
        }
    }
}
EOF

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
    @Inject(method = "onMouseButton", at = @At("HEAD"))
    private void onMouseButton(long window, int button, int action, int mods, CallbackInfo ci) {
        if (action == GLFW.GLFW_PRESS) {
            if (button == GLFW.GLFW_MOUSE_BUTTON_LEFT)  ClickTracker.onLeftClick();
            if (button == GLFW.GLFW_MOUSE_BUTTON_RIGHT) ClickTracker.onRightClick();
        }
    }
}
EOF

cat > "${RES_DIR}/fabric.mod.json" << 'EOF'
{
  "schemaVersion": 1,
  "id": "blender-client",
  "version": "${version}",
  "name": "BleNdEr Client",
  "description": "Client-side visual QoL and HUD mod.",
  "authors": ["MiK_SSER"],
  "license": "MIT",
  "environment": "client",
  "entrypoints": {
    "client": [
      "com.mik_sser.blenderclient.BlenderClient"
    ]
  },
  "mixins": [
    "blender-client.mixins.json"
  ],
  "depends": {
    "fabricloader": ">=0.16.9",
    "minecraft": "~1.21.1",
    "java": ">=21",
    "fabric-api": "*"
  }
}
EOF

cat > "${RES_DIR}/blender-client.mixins.json" << 'EOF'
{
  "required": true,
  "minVersion": "0.8",
  "package": "com.mik_sser.blenderclient.mixin",
  "compatibilityLevel": "JAVA_21",
  "client": [
    "GameRendererMixin",
    "MouseMixin"
  ],
  "injectors": {
    "defaultRequire": 1
  }
}
EOF

cat > "${ASSETS_DIR}/lang/en_us.json" << 'EOF'
{
  "key.blender-client.menu": "Open BleNdEr Menu",
  "category.blender-client": "BleNdEr Client"
}
EOF

echo ">>> Done!"
