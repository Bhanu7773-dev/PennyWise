import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pennywise/widgets/card_designs.dart';
import '../providers/money_provider.dart';

class DesignPlaygroundScreen extends StatelessWidget {
  const DesignPlaygroundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Scaffold(
      backgroundColor: isLight ? Colors.white : const Color(0xFF0F111A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isLight ? Colors.black : Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Design Playground',
          style: TextStyle(color: isLight ? Colors.black : Colors.white),
        ),
      ),
      body: Consumer<MoneyProvider>(
        builder: (context, provider, _) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Default Card Option
            CardDesignSelector(
              designId: 'default',
              provider: provider,
              label: 'Default',
              child: Container(
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: isLight
                      ? Colors.transparent
                      : Colors.white.withOpacity(0.04),
                  border: isLight ? Border.all(color: Colors.black) : null,
                ),
                child: Center(
                  child: Icon(
                    Icons.credit_card,
                    color: isLight
                        ? Colors.black
                        : Colors.white.withOpacity(0.7),
                    size: 60,
                  ),
                ),
              ),
            ),

            // Card Design Options
            // NEW NATURE & THEME DESIGNS
            CardDesignSelector(
              designId: 'ocean_wave',
              provider: provider,
              label: 'Ocean Wave',
              child: OceanWaveHeader(provider: provider),
            ),
            CardDesignSelector(
              designId: 'forest_green',
              provider: provider,
              label: 'Forest Green',
              child: ForestGreenHeader(provider: provider),
            ),
            CardDesignSelector(
              designId: 'sunset_orange',
              provider: provider,
              label: 'Sunset Orange',
              child: SunsetOrangeHeader(provider: provider),
            ),
            CardDesignSelector(
              designId: 'midnight_blue',
              provider: provider,
              label: 'Midnight Blue',
              child: MidnightBlueHeader(provider: provider),
            ),
            CardDesignSelector(
              designId: 'lavender_dream',
              provider: provider,
              label: 'Lavender Dream',
              child: LavenderDreamHeader(provider: provider),
            ),
            CardDesignSelector(
              designId: 'crimson_red',
              provider: provider,
              label: 'Crimson Red',
              child: CrimsonRedHeader(provider: provider),
            ),
            CardDesignSelector(
              designId: 'arctic_white',
              provider: provider,
              label: 'Arctic White',
              child: ArcticWhiteHeader(provider: provider),
            ),
            CardDesignSelector(
              designId: 'desert_sand',
              provider: provider,
              label: 'Desert Sand',
              child: DesertSandHeader(provider: provider),
            ),
            CardDesignSelector(
              designId: 'galaxy_purple',
              provider: provider,
              label: 'Galaxy Purple',
              child: GalaxyPurpleHeader(provider: provider),
            ),
            CardDesignSelector(
              designId: 'emerald_green',
              provider: provider,
              label: 'Emerald Green',
              child: EmeraldGreenHeader(provider: provider),
            ),

            // GLASSMORPHISM COLLECTION
            _buildSectionTitle(context, '━━━ GLASSMORPHISM COLLECTION ━━━'),
            const SizedBox(height: 24),

            CardDesignSelector(
              designId: 'amex_platinum_glass',
              provider: provider,
              label: 'Amex Platinum Glass',
              child: AmexPlatinumGlassHeader(provider: provider),
            ),
            CardDesignSelector(
              designId: 'amex_gold_frosted',
              provider: provider,
              label: 'Amex Gold Frosted',
              child: AmexGoldFrostedHeader(provider: provider),
            ),
            CardDesignSelector(
              designId: 'amex_centurion',
              provider: provider,
              label: 'Amex Centurion (Black)',
              child: AmexCenturionHeader(provider: provider),
            ),
            CardDesignSelector(
              designId: 'visa_infinite_glass',
              provider: provider,
              label: 'Visa Infinite Glass',
              child: VisaInfiniteGlassHeader(provider: provider),
            ),
            CardDesignSelector(
              designId: 'mastercard_world_elite',
              provider: provider,
              label: 'Mastercard World Elite',
              child: MastercardWorldEliteHeader(provider: provider),
            ),
            CardDesignSelector(
              designId: 'frosted_ocean_glass',
              provider: provider,
              label: 'Frosted Ocean Glass',
              child: FrostedOceanGlassHeader(provider: provider),
            ),
            CardDesignSelector(
              designId: 'aurora_borealis_glass',
              provider: provider,
              label: 'Aurora Borealis Glass',
              child: AuroraBorealisGlassHeader(provider: provider),
            ),
            CardDesignSelector(
              designId: 'sapphire_reserve_glass',
              provider: provider,
              label: 'Sapphire Reserve Glass',
              child: SapphireReserveGlassHeader(provider: provider),
            ),
            const SizedBox(height: 32),

            // FUTURE & COSMIC COLLECTION
            _buildSectionTitle(context, '━━━ FUTURE & COSMIC ━━━'),
            const SizedBox(height: 24),

            CardDesignSelector(
              designId: 'cosmic_nebula',
              provider: provider,
              label: 'Cosmic Nebula',
              child: CosmicNebulaHeader(provider: provider),
            ),
            CardDesignSelector(
              designId: 'quantum_dot',
              provider: provider,
              label: 'Quantum Dot',
              child: QuantumDotHeader(provider: provider),
            ),
            CardDesignSelector(
              designId: 'liquid_gold',
              provider: provider,
              label: 'Liquid Gold',
              child: LiquidGoldHeader(provider: provider),
            ),
            CardDesignSelector(
              designId: 'cyber_glitch',
              provider: provider,
              label: 'Cyber Glitch',
              child: CyberGlitchHeader(provider: provider),
            ),
            CardDesignSelector(
              designId: 'zen_garden',
              provider: provider,
              label: 'Zen Garden',
              child: ZenGardenHeader(provider: provider),
            ),
            CardDesignSelector(
              designId: 'retro_vaporwave',
              provider: provider,
              label: 'Retro Vaporwave',
              child: RetroVaporwaveHeader(provider: provider),
            ),
            CardDesignSelector(
              designId: 'neon_city',
              provider: provider,
              label: 'Neon City',
              child: NeonCityHeader(provider: provider),
            ),
            CardDesignSelector(
              designId: 'prism_refraction',
              provider: provider,
              label: 'Prism Refraction',
              child: PrismRefractionHeader(provider: provider),
            ),
            CardDesignSelector(
              designId: 'obsidian_shard',
              provider: provider,
              label: 'Obsidian Shard',
              child: ObsidianShardHeader(provider: provider),
            ),
            CardDesignSelector(
              designId: 'bioluminescence',
              provider: provider,
              label: 'Bioluminescence',
              child: BioluminescenceHeader(provider: provider),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Text(
      title,
      style: TextStyle(
        color: isLight
            ? Colors.black.withOpacity(0.7)
            : Colors.white.withOpacity(0.7),
        fontSize: 14,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.0,
      ),
    );
  }
}

// --- Card Design Selector Widget ---
class CardDesignSelector extends StatelessWidget {
  final String designId;
  final MoneyProvider provider;
  final Widget child;
  final String? label;
  const CardDesignSelector({
    required this.designId,
    required this.provider,
    required this.child,
    this.label,
    super.key,
  });
  @override
  Widget build(BuildContext context) {
    final isSelected = provider.selectedCardDesign == designId;
    return GestureDetector(
      onTap: () => provider.setSelectedCardDesign(designId),
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? Colors.amber : Colors.transparent,
            width: 3,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.amber.withOpacity(0.2),
                    blurRadius: 16,
                  ),
                ]
              : [],
        ),
        child: Stack(
          children: [
            child,
            if (isSelected)
              Positioned(
                top: 12,
                right: 12,
                child: Icon(Icons.check_circle, color: Colors.amber, size: 28),
              ),
            if (label != null)
              Positioned(
                left: 16,
                top: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    label!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
