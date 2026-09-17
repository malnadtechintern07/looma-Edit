#!/usr/bin/env python3
import re
import os

# Define the 52 long, specific, pro-grade masterpiece prompts
PROMPTS = {
    'photo_80s_synthwave': (
        "Authentic 1980s retro synthwave portrait of a stylish protagonist wearing classic mirrored aviator sunglasses and a distressed black leather bomber jacket with neon pink interior lining, leaning against a vintage sports car. Background features a luminous neon grid horizon fading into a giant retro sun with purple and orange horizontal lines. Volumetric magenta, hot cyan, and violet rim lighting striking cheekbones and shoulders. Subtle VHS tape tracking distortion, analog 35mm film grain, chromatic aberration at the lens perimeter, Kodachrome 64 color science, ultra-detailed 8K photorealism."
    ),
    'photo_80s_polaroid': (
        "Nostalgic 1985 flash snapshot polaroid photo captured in a bustling retro discotheque, candid smiling subject holding a vintage drink with holographic streamer decorations dancing in the background. Direct, unsoftened on-camera xenon flash creating crisp cast shadows, authentic vintage warm golden color grading with faded cyan shadows, tactile chemical paper texture, slight light leak along the bottom margin, organic Kodak 400 film grain, authentic 8K instant photography aesthetic."
    ),
    'photo_80s_pastel_vaporwave': (
        "Dreamy aesthetic 90s vaporwave synthpop artistic portrait, subject draped in soft pastel oversized streetwear gazing into the distance. Surreal sunset sky blending cotton-candy pink, soft lavender, and mint green gradients with floating translucent geometric wireframe prisms and glowing neon palm tree silhouettes. A classical Greek marble bust glowing softly in the background. Lo-Fi VHS scanlines, subtle prismatic light diffraction, Fuji Pro 400H color palette, 8K ultra-detailed photorealistic portrait."
    ),
    'photo_80s_miami_sunset': (
        "Cinematic 1984 Miami Vice golden hour portrait, subject dressed in a sharp unbuttoned ivory linen blazer over a pastel teal t-shirt, standing beside the South Beach ocean boulevard. Dramatic low-angle tropical sunset with glowing fiery orange and magenta hues illuminating silhouettes of towering royal palm trees. Reflections of art deco hotel neon signs shimmering across the chrome hood of a vintage Ferrari Testarossa. Shot on 85mm f/1.4 Cine lens with anamorphic flares and warm 35mm film warmth."
    ),
    'photo_80s_arcade_neon': (
        "Atmospheric 1980s neon arcade portrait, subject sitting in front of classic glowing CRT arcade cabinets displaying pixelated space shooter games. Vivid cyan and hot magenta cathode-ray tube phosphor glow illuminating facial features and reflections in dark pupils. Retro foam-cushioned headphones resting around the neck, acid-wash denim jacket adorned with enamel retro badges, soft atmospheric haze and dust motes suspended in beams of colored arcade light, 8K cinematic Kodacolor aesthetic."
    ),
    'photo_trending_cyberpunk': (
        "Masterpiece 8K photorealistic editorial portrait of a charismatic cyberpunk protagonist standing in the pouring rain of Neo-Tokyo Shinjuku alleyways at 2:00 AM, transparent umbrella catching prismatic raindrops and reflecting neon billboards, wearing a distressed oversized matte-black technical bomber jacket with luminous cyan fiber-optic seams and glowing Japanese Kanji typography patches, wet slicked-back raven hair with water droplets clinging to eyelashes and cheekbones, high-detail skin texture with visible natural pores and subtle subsurface scattering, hyper-realistic cybernetic eye implant with glowing amber aperture ring, wet asphalt streets reflecting brilliant electric magenta, ultraviolet, and turquoise signage, dense volumetric steam and atmospheric mist rising from street drainage grates, shot on Hasselblad H6D-100c with 85mm f/1.2 Cine Prime lens, creamy anamorphic bokeh, delicate edge halation, cinematic teal and orange color grading, ray-traced reflections, award-winning cinematography."
    ),
    'photo_cyber_samurai': (
        "Masterpiece cinematic cyberpunk portrait of a legendary cyber-samurai ronin standing atop a rain-soaked Neo-Kyoto skyscraper rooftop overlooking an endless neon metropolis. Wearing custom matte-black carbon-fiber samurai armor with glowing crimson LED trim and battle-scratched pauldrons, half-face titanium Oni demon mask with glowing vent ports. Wielding an energized katana blade radiating brilliant electric cyan plasma and heat distortion particles into the night air. Torrential downpour splashing against armor plating, distant flying hovercraft headlights cutting through dense industrial smog, 8K ray-traced reflections, octane render, stunning cinematic composition."
    ),
    'photo_trending_golden_glow': (
        "Breathtaking sun-drenched golden hour portrait taken in a wild blooming meadow during peak sunset. Low golden sun directly behind the subject producing magnificent warm halation, golden rim lighting tracing every strand of wind-tousled hair, natural freckles across the nose bridge, soft glowing skin with radiant warmth. Floating dust motes and dandelion seeds illuminated like tiny embers in the amber sunlight. Captured on 85mm f/1.2 lens wide open at f/1.4, creamy circular optical bokeh, pastel warm peach and honey color grading, Vogue editorial quality, photorealistic 8K UHD."
    ),
    'photo_trending_seoul_night': (
        "Candid nighttime editorial street portrait taken in the bustling neon-drenched night markets of Hongdae, Seoul. Subject wearing contemporary oversized minimalist Korean fashion with a wool trench coat and layered silver chain jewelry. Glowing red and yellow pojangmacha tent lighting mingling with vibrant Korean street signage and steaming street food carts in the soft-focused background. Delicate rain mist creating a shimmering glow on the damp pavement, shallow depth of field with luminous bokeh, natural skin tones, Sony A7R V with 50mm f/1.2 GM lens, cinematic K-drama film grade."
    ),
    'photo_trending_metaverse_avatar': (
        "Futuristic high-fashion metaverse virtual human portrait, flawless luminous skin with iridescent micro-glitter shimmer and subtle translucent silicone subdermal glow. Geometric floating glass shards and prismatic holographic UI data rings orbiting around the subject's head. Draped in liquid chrome sculpted fabric that shifts color from platinum to violet under ambient digital studio lighting. Pure dark void background with delicate particle dust, ultra-clean studio key light with cyan fill, rendered with Hyper-Unreal Engine 5 photorealism, 8K resolution, transcendent digital beauty."
    ),
    'photo_trending_kpop_stage': (
        "Electrifying live K-Pop stadium concert stage portrait, charismatic idol caught mid-performance under dramatic crisscrossing laser beams and sweeping arena stage spotlights. Wearing custom avant-garde stage outfit adorned with Swarovski crystals, metallic embroidery, and high-shine patent leather. Beads of perspiration glistening along the temples and collarbone under intense magenta, violet, and gold stage lights, energetic facial expression, high-speed confetti bursting in the air, captured with high-speed telephoto lens at 1/1000s, crisp dynamic focus, 8K concert photography."
    ),
    'photo_editorial_prismatic_crystal': (
        "Avant-garde high-fashion editorial portrait, subject photographed through a heavy multi-faceted optical crystal prism. Beams of natural sunlight splitting into brilliant rainbow chromatic caustics, kaleidoscopic flares, and vivid color bands cascading across high-fashion makeup and porcelain skin. Bold sculptural glass jewelry reflecting liquid spectrums of violet, emerald, and amber light. High-end Vogue cover aesthetic, minimalist neutral background, ultra-sharp detail on eye iris and lashes, shot on medium format Phase One 150MP camera, award-winning editorial lighting."
    ),
    'photo_editorial_haute_couture': (
        "Paris Fashion Week haute couture editorial portrait, model wearing a groundbreaking sculptural gown crafted from molded mirror-polished chrome and pleated midnight-black silk taffeta. High architectural collar framing a striking, poised facial expression with dark plum high-gloss lips and graphic metallic eyeliner. Dramatic Caravaggio chiaroscuro side lighting against a stark minimalist concrete architectural set. Crisp reflections of the runway spotlights bouncing off the polished chrome bodice, 8K masterwork fashion photography."
    ),
    'photo_popular_urban_street': (
        "High-energy modern streetwear lifestyle portrait set in downtown Brooklyn at twilight. Subject wearing an oversized distressed vintage graphic hoodie, utility cargo vest with technical carabiners, and limited-edition hype sneakers, seated nonchalantly on an industrial steel fire escape. Distant yellow taxi headlights and glowing storefront neon signs casting warm amber and cool slate-blue contrast. Gritty urban textures of aged brick walls and steel rivets, candid street culture vibe, captured on 35mm Leica M11 with Summilux 35mm f/1.4 lens, authentic filmic grain."
    ),
    'photo_editorial_paris_midnight': (
        "Romantic Parisian midnight cinematic portrait on the Pont Alexandre III bridge over the Seine River. Soft rain creating reflective wet cobblestones under the glow of ornate golden Belle Époque lampposts. Subject wrapped in a chic belted camel cashmere coat with a silk scarf gently billowing in the river breeze, silhouetted architecture of Paris in the background with distant golden lights. Moody deep navy and warm amber color palette, vintage French New Wave cinema atmosphere, 8K resolution."
    ),
    'photo_editorial_met_gala_gold': (
        "Opulent Met Gala red carpet portrait, celebrity wearing a breathtaking custom gown made of sculpted molten liquid 24K gold that flows seamlessly down the body like a second skin. Intricate filigree neckpiece and delicate gold leaf pressed into the hair and cheekbones, catching thousands of flashing camera strobes. Opulent grand staircase lined with crimson velvet carpet and exotic floral arches, grand gala atmosphere, ultra-luxury high-fashion photography, 8K sharp detail."
    ),
    'photo_editorial_vogue_minimal': (
        "Iconic black and white Vogue studio portrait, timeless minimalist aesthetic. Striking chiaroscuro lighting sculpting the cheekbones, jawline, and collarbones with deep rich charcoal shadows and luminous soft highlights. Subject wearing an elegant high-neck black turtleneck sweater, direct piercing gaze into the camera lens with quiet confidence. Immaculate skin texture with fine pores and natural imperfections intact, zero digital artifacts, shot on Kodak Tri-X 400 black and white film with silver gelatin print tonality."
    ),
    'photo_sci_fi_astronaut': (
        "Epic cinematic deep-space astronaut portrait, subject wearing a weathered high-tech extravehicular spacesuit with detailed life-support modules, titanium carabiners, and thermal insulation fabric. Mirrored gold-coated visor reflecting a swirling celestial nebula of violet stardust, magenta cosmic dust clouds, and brilliant distant star clusters. Volumetric stellar light illuminating the helmet rim and shoulder patches with icy blue and cosmic purple tones, deep obsidian cosmos background, interstellar exploration theme, shot on Panavision 70mm lens, 8K photorealism."
    ),
    'photo_cyberpunk_neon_geisha': (
        "Futuristic cyberpunk neo-geisha portrait in an upscale Neo-Tokyo sky-lounge. Traditional porcelain white face makeup contrasting with intricate glowing gold fiber-optic circuitry patterns tracing down the neck and collarbone. Elaborate sculptural hair adorned with metallic kanzashi hairpins and glowing neon fiber cables. Wearing a kimono crafted from translucent holographic smart-fabric that shimmers between iridescent turquoise and hot magenta. Cybernetic mechanical fingers holding a delicate porcelain sake cup, rainy skyline visible through floor-to-ceiling windows, 8K cinematic detail."
    ),
    'photo_cyberpunk_neon_noir': (
        "Moody cyberpunk neon-noir detective portrait, solitary figure in a wet trench coat with an upturned collar standing under a flickering holographic neon sign in a desolate industrial alleyway. Dense cigarette smoke curling upwards through heavy blue rain and amber light beams. Hard rain droplets dripping from the brim of a fedora hat, cybernetic eye enhancement casting a faint scanning reticle into the shadows, dramatic film noir low-key lighting with high-contrast shadows, 8K masterwork."
    ),
    'photo_scifi_orbital_commander': (
        "Authoritative sci-fi orbital fleet commander portrait on the command bridge of an interstellar dreadnought starship. Crisp military tactical officer uniform with glowing rank insignias, brass accents, and holographic telemetry wrist gauntlet. Massive panoramic observation windows overlooking a swirling gas giant planet with concentric golden rings and orbiting star cruisers. Soft ambient glow from blue control console screens illuminating the stern, focused facial expression, 8K cinematic lighting."
    ),
    'photo_scifi_android_circuitry': (
        "Hyper-detailed biomechanical bionic android portrait, face featuring exposed micro-circuitry, delicate gold-plated wiring, and miniature hydraulic pistons seamlessly integrated beneath translucent synthetic skin. Piercing sapphire-blue glowing optical sensors with realistic iris aperture mechanisms. Minimalist dark cyber-laboratory setting with clean cool clinical studio lighting and warm gold rim highlights, extreme macro detail of metallic textures and silicone surfaces, 8K ultra-realistic render."
    ),
    'photo_scifi_cyber_hacker': (
        "Intense underground netrunner hacker portrait in a hidden tech bunker surrounded by arrays of flickering multi-monitor displays showing cascading green terminal code, network topographies, and decrypted data streams. Subject wearing a dark oversized hoodie with hood pulled low, reflective holographic glasses displaying data reflections, fingers poised over a custom mechanical cyberpunk keyboard, blue and green ambient LED glow, dense atmospheric room haze, 8K cinematic realism."
    ),
    'photo_fantasy_nordic_viking': (
        "Fierce historical Nordic Viking shieldmaiden portrait standing on a windswept icy fjord bluff in Scandinavia. Weathered braided blonde hair woven with bone beads and leather cords, war paint across the eyes in charcoal and woad blue. Wearing heavy tailored fur cloak over embossed leather lamellar armor with bronze battle brooches. Holding a battle-scarred round wooden shield with carved dragon motifs, snow flurries swirling in the frigid northern gale, overcast moody Arctic sky, national geographic documentary quality, 8K photorealistic detail."
    ),
    'photo_fantasy_underwater_siren': (
        "Ethereal mythical underwater siren portrait submerged in deep crystalline turquoise ocean waters. Flowing iridescent mermaid hair billowing weightlessly like silk in the gentle currents, surrounded by schools of glowing bioluminescent fish and ascending micro-air bubbles. Skin adorned with delicate mother-of-pearl scales reflecting dancing sunbeams and optical caustics penetrating from the water's surface above. Dreamy deep blue underwater atmosphere, cinematic ocean photography, shot on underwater housing with ultra-wide cinema lens, 8K masterwork."
    ),
    'photo_fantasy_enchanted_elf': (
        "Bioluminescent woodland elf royal portrait deep within an ancient mystical twilight forest. Pointed elegant ears adorned with delicate silver filigree cuffs, cascading silver hair woven with glowing starlight blossoms and emerald ivy vines. Translucent ethereal skin glowing with soft inner fairy light, wearing an organic dress woven of luminous leaves and shimmering moon-spider silk. Giant ancient moss-covered trees, floating magical pollen embers, and gentle sunbeams piercing misty canopy, 8K high-fantasy concept art."
    ),
    'photo_fantasy_egyptian_pharaoh': (
        "Majestic ancient Egyptian Pharaoh portrait inside a torchlit sandstone temple sanctum. Wearing an authentic ceremonial Nemes headdress of blue lapis lazuli and hammered solid gold, ceremonial golden uraeus cobra rearing from the forehead. Regal collar necklace composed of turquoise, carnelian, and pure gold beads, kohl-rimmed eyes with intense divine gaze. Warm dancing flames from bronze fire braziers casting dramatic golden highlights and deep hieroglyph shadows across sandstone pillars, 8K cinematic masterpiece."
    ),
    'photo_fantasy_celestial_angel': (
        "Magnificent celestial seraph angel portrait in heavenly cloudscapes at dawn. Massive hyper-detailed feathered wings spanning outward, each feather tipped with luminous iridescent gold foil and glowing divine light. Wearing flowing pure white gossamer robes embroidered with celestial constellations in silver thread, glowing radiant halo of pure sunlight hovering above the head. Golden sunrise clouds stretching to the horizon, divine godrays breaking through atmospheric mist, religious renaissance masterwork painting aesthetic, 8K resolution."
    ),
    'photo_fantasy_moon_priestess': (
        "Mystical Celtic moon priestess portrait standing inside an ancient prehistoric stone circle beneath a radiant full silver moon. Draped in a hooded midnight-blue velvet cloak lined with silver silk, holding an ornate silver staff crowned with a glowing natural moonstone orb. Silver lunar crescent tiara resting on forehead, delicate glowing runic tattoos tracing the temples and hands, soft night mist rolling over mossy megalith stones, eerie silver moonbeams illuminating the serene face, 8K high-fantasy photorealism."
    ),
    'photo_new_steampunk_inventor': (
        "Intricate Victorian steampunk inventor portrait inside a cluttered brass clockwork laboratory filled with rotating gears, ticking pendulum clocks, and bubbling copper distillation retorts. Subject wearing leather artisan apron over rolled-up linen shirt sleeves, multi-lens brass magnifying goggles pushed up onto forehead, brass mechanical gauntlet with miniature pressure gauges on right arm. Atmospheric amber sunlight streaming through dusty industrial factory windows, warm sepia tones, cinematic steam plumes, 8K vintage aesthetic."
    ),
    'photo_vintage_dark_academia': (
        "Atmospheric Gothic dark academia portrait inside an ancient university library surrounded by floor-to-ceiling mahogany bookshelves stacked with leather-bound antique grimoires. Subject wearing a tailored tweed wool blazer, cable-knit turtleneck sweater, and tortoiseshell round spectacles, reading an aged manuscript by warm flickering candlelight. Stained glass gothic arched windows casting faint jewel-toned reflections onto polished parquet floor, scholarly intellectual mood, warm rich amber and mahogany palette, 8K cinematic portrait."
    ),
    'photo_vintage_1940s_film_noir': (
        "Classic 1940s Hollywood golden-age film noir portrait, dramatic hard shadow lines cast through venetian blinds across the subject's face. Suited detective with a loosened vintage silk tie, cigarette smoke rising in undulating white ribbons against a dark mahogany office door. Dramatic low-key lighting with razor-sharp contrast between pure black shadows and glowing rim highlights, authentic silver nitrate film emulsion texture, timeless vintage Hollywood glamour, 8K black and white masterpiece."
    ),
    'photo_vintage_90s_kodak': (
        "Nostalgic 1990s analog 35mm candid portrait shot on Kodak Gold 200 film stock. Subject lounging casually on a vintage floral sofa in a sunlit apartment, wearing vintage high-waisted denim jeans and an oversized band tee. Warm golden color saturation, gentle halation around window highlights, authentic soft grain structure, authentic 90s indie cinema aesthetic, relaxed candid human moment, 8K analog photography."
    ),
    'photo_vintage_70s_boho_sun': (
        "Sun-kissed 1970s bohemian Woodstock festival portrait, subject wearing an embroidered bell-sleeve peasant blouse, suede fringe vest, and round rose-tinted sunglasses, wind blowing through wavy tousled hair. Sunset in a golden wheat field with giant golden sun flare obscuring part of the frame in warm vintage amber haze. Rich retro saturated colors, Kodak Ektachrome film color profile, joyful free-spirited retro summer aesthetic, 8K photorealism."
    ),
    'photo_vintage_cinematic_mood': (
        "Moody European art-house cinema portrait captured inside a vintage 1960s passenger train compartment moving through a foggy countryside. Subject gazing pensively through rain-streaked window glass, warm amber lamp light reflecting in condensation droplets. Muted earth-tone color grading inspired by Andrei Tarkovsky and Wong Kar-wai, cinematic 2.39:1 widescreen framing, soft film grain, introspective emotional depth, 8K cinematic film still."
    ),
    'photo_popular_anime': (
        "Vibrant modern anime art portrait in the signature style of Makoto Shinkai and CoMix Wave Films. Stunning anime girl with expressive violet eyes and wind-swept flowing hair, standing on a Tokyo pedestrian bridge at golden hour sunset. Swirling pink cherry blossom sakura petals drifting through the air, hyper-detailed volumetric clouds glowing with peach, orange, and purple sunset light, photorealistic anime background with glowing train signals, masterwork digital anime illustration, 8K resolution."
    ),
    'photo_anime_sakura_watercolor': (
        "Traditional Japanese watercolor and sumi-e ink anime portrait, delicate ink brushstrokes delineating a serene samurai maiden amidst blooming sakura branches. Soft transparent watercolor washes in rose pink, cerulean blue, and tea-stained ivory diffusing into handmade washi rice paper texture. Splash ink splatter effects, elegant calligraphic outlines, peaceful poetic Japanese aesthetic, award-winning anime fine art."
    ),
    'photo_anime_fantasy': (
        "Whimsical anime forest fantasy portrait in the enchanting pastoral aesthetic of Studio Ghibli and Hayao Miyazaki. Young magic apprentice with a friendly woodland sprite creature resting on shoulder, walking through a lush mossy ancient forest with giant sunbeams piercing through emerald green ferns and mushrooms. Warm hand-painted background art, cozy heartwarming atmosphere, vibrant joyful colors, nostalgic storytelling quality, 8K anime art."
    ),
    'photo_anime_cyber_mecha': (
        "High-octane cyberpunk mecha anime pilot portrait, character strapped into the cockpit of a humanoid mecha robot. Glowing multi-layered holographic HUD displays projecting targeting reticles, vital statistics, and wireframe schematics in front of intense, determined eyes. Specialized armored pilot flight suit with life-support hoses and LED status lights, cockpit interior glowing with amber warning indicators and blue reactor energy, Studio Trigger dynamic anime aesthetic, 8K detail."
    ),
    'photo_anime_retro_city_pop': (
        "Retro 1980s Japanese anime city pop portrait, inspired by classic 80s OVA animations and retro manga covers. Stylish subject driving a vintage convertible along the Tokyo Shuto Expressway at night, cassette tape playing on the dashboard. Neon skyline of 1980s Tokyo towering in the background with glowing kanji signs and pastel gradients. Characteristic cel-shaded aesthetic, hand-drawn look with nostalgic pastel glow, 8K retro anime illustration."
    ),
    'photo_anime_lofi_aesthetic': (
        "Cozy lo-fi hip-hop study beats anime portrait, subject wearing oversized headphones leaning on a wooden study desk beside a large rain-streaked window at twilight. Soft warm desk lamp illuminating open notebook, coffee mug with rising steam, and a sleeping tabby cat curled on the windowsill. Distant city lights sparkling in soft blurred pastel circles through the rain, calm relaxing lo-fi aesthetic, warm muted color palette, 8K anime illustration."
    ),
    'photo_new_3d_pixar': (
        "Charming 3D animated character portrait in the signature style of modern Pixar and Disney Animation Studios. Expressive, oversized warm brown eyes with lifelike light catchlights, cheerful charismatic smile, individually styled strands of soft stylized hair catching the light. Soft peach skin with subtle subsurface scattering and cute freckles, wearing a cozy knitted wool sweater with realistic yarn fuzz and weave. Warm inviting studio portrait lighting, soft blurred pastel background, award-winning 3D feature film quality, 8K Octane render."
    ),
    'photo_3d_pixar_magic': (
        "Magical 3D animated hero portrait, young apprentice holding a glowing crystalline magic wand that emits swirling golden and cyan energy sparks. Wonder and excitement in wide expressive eyes, finely detailed fantasy traveler tunic with leather stitching and brass buckles. Atmospheric magical particles and glowing butterflies orbiting the scene, warm Disney-style magical lighting, vibrant color harmony, cinematic 3D animation still, 8K resolution."
    ),
    'photo_3d_cozy_creature': (
        "Adorable 3D animated woodland creature portrait, a tiny fluffy fantasy forest dweller with large inquisitive glass-like eyes, soft velvety fur with individual fur grooming details, wearing a miniature knitted scarf and acorn cap. Sitting atop a mossy forest stone surrounded by dewdrops and glowing clover blossoms, soft dappled forest sunlight filtering through leaves, heartwarming whimsical 3D render, 8K Pixar aesthetic."
    ),
    'photo_3d_claymation_art': (
        "Artisanal stop-motion claymation character portrait in the handcrafted tactile style of Aardman and Laika Studios. Visible organic fingerprint textures and miniature sculpting tool marks in the colorful polymer clay surfaces. Hand-stitched miniature fabric clothing, tiny glass bead buttons, warm physical studio miniature lighting casting soft gentle shadows, authentic whimsical stop-motion animated cinema aesthetic, 8K macro photography."
    ),
    'photo_cinematic_blade_runner': (
        "Epic cinematic portrait in the atmospheric sci-fi visual style of Blade Runner 2049, Denis Villeneuve cinematography. Subject standing in the desolate orange dust storm ruins of an ancient mega-monument, wearing a distressed heavy shearling coat. Dense monochromatic amber and tangerine volumetric haze obscuring towering geometric Brutalist architecture. Dramatic silhouette with intense rim light piercing through the dust, shot on ARRI Alexa 65 with 70mm anamorphic prime lens, award-winning cinematic grandeur, 8K masterwork."
    ),
    'photo_cinematic_monochrome_rain': (
        "Stunning black and white cinematic rain portrait, subject walking under heavy downpour on an empty city street at night. Dramatic single streetlight backlighting millions of individual suspended raindrops like falling crystals. Deep obsidian blacks, rich textured mid-tones, and pure white specular reflections on wet asphalt. Intense cinematic mood, film noir gravitas, captured on Leica Monochrom camera with 50mm f/0.95 Noctilux lens, award-winning fine art photography."
    ),
    'photo_cinematic_desert_mirage': (
        "Monumental desert mirage cinematic portrait, solitary traveler traversing the shifting crest of immense Sahara sand dunes under a scorching desert sun. Flowing gossamer linen robes rippling in the hot thermal desert wind, heat shimmer ripples distorting the distant horizon. Warm terracotta and gold sand textures with razor-sharp wind-carved ridges, breathtaking high-contrast natural sunlight, Lawrence of Arabia epic scale, 8K cinematography."
    ),
    'photo_cinematic_interstellar': (
        "Awe-inspiring sci-fi cinematic portrait on an alien ice planet in a distant galaxy. Planetary explorer in a weathered pressurized hazard suit walking across vast jagged frozen methane glaciers. In the sky above, a titanic spinning black hole with a blinding golden accretion disk and gravitationally lensed light rings dominates the celestial horizon. Deep cold cyan ice contrast against radiant golden gravitational light, Panavision 65mm IMAX cinematography, 8K photorealism."
    ),
    'photo_gothic_victorian_vampire': (
        "Alluring Victorian gothic vampire noble portrait inside a decadent decaying baroque castle salon. Flawless pale alabaster skin contrasting with deep crimson velvet frock coat, black lace cravat, and antique silver signet rings with blood-red garnets. Piercing scarlet-tinted eyes with hypnotic intensity, ornate candelabras with dripping black wax casting flickering dramatic candle flames, antique oil paintings on shadowy damask wallpaper, Bram Stoker gothic horror romance, 8K masterwork."
    ),
    'photo_gothic_crimson_sorceress': (
        "Haunting dark fantasy sorceress portrait standing in a misty autumnal forest of gnarled blackthorn trees. Wearing an elaborate gown of shredded crimson silk and raven feathers, floating black smoke tendrils and dancing embers swirling around outstretched clawed fingers. Intricate black filigree crown adorned with polished obsidian crystals, eerie moonlight filtering through spectral fog, dark supernatural elegance, 8K high-fantasy dark art."
    ),
    'photo_new_tropical_sunset': (
        "Vibrant tropical luxury resort sunset portrait, subject lounging on a teak infinity deck overlooking the turquoise waters of a secluded Polynesian lagoon. Golden sunset painting the sky in fiery orange, hibiscus pink, and violet clouds, warm tropical breeze rustling towering coconut palms. Wet skin glistening with natural sea mist and tropical coconut oil, wearing a relaxed linen resort shirt, cocktail glass reflecting the sunset colors, high-end Conde Nast Traveler photography, 8K resolution."
    ),
}

# 1. Update Dart file
dart_path = '/Users/apple/Desktop/ProCut/lib/features/ai_photo_edit/data/ai_photo_presets_data.dart'
with open(dart_path, 'r', encoding='utf-8') as f:
    dart_text = f.read()

# Update each prompt in dart_text
updated_count = 0
for pid, long_prompt in PROMPTS.items():
    # Find block for this id
    pattern = re.compile(
        rf"(id:\s*'{pid}',[\s\S]*?prompt:\s*\n?\s*)'([^']+)'([,\s\S]*?negativePrompt:)",
        re.MULTILINE
    )
    m = pattern.search(dart_text)
    if m:
        # replace
        prefix = m.group(1)
        suffix = m.group(3)
        # Escape single quotes in prompt
        clean_prompt = long_prompt.replace("'", "\\'")
        new_block = f"{prefix}'{clean_prompt}'{suffix}"
        dart_text = dart_text[:m.start()] + new_block + dart_text[m.end():]
        updated_count += 1
    else:
        print(f"Warning: could not match ID {pid} in Dart file")

with open(dart_path, 'w', encoding='utf-8') as f:
    f.write(dart_text)

print(f"Updated {updated_count} prompts in {dart_path}")
