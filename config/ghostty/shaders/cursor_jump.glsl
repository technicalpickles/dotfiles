// ============================================================================
// CURSOR JUMP SHADER - Highlights cursor when it jumps (e.g., tmux pane switch)
// ============================================================================
// Adapted from Martin Emde's focus_cursor.glsl
// Triggers on large cursor movements instead of window focus changes
// ============================================================================

const float ANIM_DURATION = 0.2;  // Animation duration in seconds

// Detect if cursor "jumped" (e.g., tmux pane switch) vs normal movement
bool didCursorJump() {
    // Calculate distance cursor moved in pixels
    float dist = distance(iCurrentCursor.xy, iPreviousCursor.xy);

    // Threshold: 30x cursor width ignores most in-editor navigation
    // (word jumps, gg/G, searching) but catches pane switches
    float threshold = iCurrentCursor.z * 30.0;

    // Minimum 200px - a tmux pane switch typically moves 400+ pixels
    // while nvim navigation rarely exceeds this in a single jump
    float minDistance = 200.0;

    return dist > max(threshold, minDistance);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;

    // Quick exit: only animate if cursor recently jumped
    float timeSinceChange = iTime - iTimeCursorChange;
    bool shouldAnimate = didCursorJump() &&
                         timeSinceChange >= 0.0 &&
                         timeSinceChange < ANIM_DURATION;

    if (!shouldAnimate) {
        fragColor = texture(iChannel0, uv);
        return;
    }

    vec4 originalColor = texture(iChannel0, uv);

    // Animation progress: 0.0 at start, 1.0 at end
    float progress = timeSinceChange / ANIM_DURATION;

    // Zoom inward: scale from 4x to 1x (smaller than focus shader)
    float scale = mix(4.0, 1.0, progress);

    // Fade in: transparent to semi-opaque
    float opacity = mix(0.1, 0.7, progress);

    // Calculate scaled cursor rectangle
    vec2 cursorSize = iCurrentCursor.zw;
    vec2 cursorCenter = iCurrentCursor.xy + vec2(cursorSize.x * 0.5, -cursorSize.y * 0.5);
    vec2 scaledSize = cursorSize * scale;
    vec2 offset = fragCoord - cursorCenter;
    vec2 halfSize = scaledSize * 0.5;

    // Soft-edged cursor shape
    vec2 edgeDist = abs(offset) - halfSize;
    float dist = max(edgeDist.x, edgeDist.y);
    float softEdge = smoothstep(2.0, -2.0, dist);

    // Only apply inside the scaled rectangle
    bool insideRect = abs(offset.x) < halfSize.x && abs(offset.y) < halfSize.y;
    float pulse = insideRect ? softEdge * opacity : 0.0;

    // Blend cursor color with original
    vec3 finalColor = mix(originalColor.rgb, iCurrentCursorColor.rgb, pulse);
    fragColor = vec4(finalColor, originalColor.a);
}
