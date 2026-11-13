// GameCard için holo folyo (animasyon kuralları: uSize, uTilt, uStrength uniform'ları).
// Kart yüzünün üstüne eklemeli olarak çizilir; çıktı önceden çarpılmıştır.
//   uStrength 0.35 nadir: soluk çapraz parlama
//   uStrength 0.65 epik: parlama + seyrek yıldız benekleri
//   uStrength 1.0  efsanevi: gökkuşağı folyo + altın kenar parıltısı
#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;     // piksel cinsinden kart boyutu
uniform vec2 uTilt;     // flutter_tilt areaProgress, yaklaşık [-1, 1]
uniform float uStrength;

out vec4 fragColor;

float hash(vec2 p) {
  return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

vec3 hue(float h) {
  vec3 k = vec3(0.0, 2.0 / 3.0, 1.0 / 3.0);
  return clamp(abs(fract(h + k) * 6.0 - 3.0) - 1.0, 0.0, 1.0);
}

void main() {
  vec2 uv = FlutterFragCoord().xy / uSize;

  // Eğimle kayan çapraz bant.
  float diag = uv.x * 0.7 + uv.y * 0.3;
  float pos = 0.5 + (uTilt.x * 0.6 - uTilt.y * 0.4) * 0.5;
  // pow(x, 2.0) değil x * x: GLSL'de pow negatif taban için tanımsızdır.
  float off = (diag - pos) * 11.0;
  float band = exp(-off * off);
  float sheen = band * 0.16 * smoothstep(0.0, 0.35, uStrength);

  vec3 color = vec3(sheen);
  float alpha = sheen;

  // Epik ve üstü: kart eğildikçe parıldayan seyrek küçük yıldızlar.
  if (uStrength > 0.5) {
    vec2 grid = vec2(14.0, 20.0);
    vec2 cell = floor(uv * grid);
    float r = hash(cell);
    vec2 center = (cell + 0.25 + 0.5 * vec2(r, hash(cell + 7.0))) / grid;
    float d = length((uv - center) * uSize);
    float spot = 1.0 - smoothstep(1.0, 2.5, d);
    float twinkle = 0.5 + 0.5 * sin(r * 40.0 + (uTilt.x + uTilt.y) * 6.0);
    float star = step(0.85, r) * spot * twinkle * 0.6;
    color += vec3(star);
    alpha += star;
  }

  // Efsanevi: gökkuşağı folyo + kenarlar boyunca altın parıltı.
  if (uStrength > 0.9) {
    float h = diag * 1.5 + uTilt.x * 0.35 + uTilt.y * 0.25;
    float foilAmount = 0.07 + 0.12 * band;
    color += hue(h) * foilAmount;
    alpha += foilAmount * 0.6;

    vec2 edge = min(uv, 1.0 - uv);
    float rim = 1.0 - smoothstep(0.0, 0.04, min(edge.x, edge.y));
    float glint = rim * band * 0.5;
    color += vec3(1.0, 0.8, 0.35) * glint;
    alpha += glint;
  }

  alpha = clamp(alpha, 0.0, 1.0);
  fragColor = vec4(min(color, vec3(alpha)), alpha);
}
