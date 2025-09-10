import 'package:flutter/material.dart';
import 'package:niit/ui/screens/scan/scanhome.dart';
import 'package:niit/ui/widgets/app_bar.dart';
import 'package:niit/utils/colors.dart';

class SizeConfig {
  static late MediaQueryData _mediaQueryData;
  static late double screenWidth;
  static late double screenHeight;

  void init(BuildContext context) {
    _mediaQueryData = MediaQuery.of(context);
    screenWidth = _mediaQueryData.size.width;
    screenHeight = _mediaQueryData.size.height;
  }

  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  double responsiveWidth(double percentage) =>
      SizeConfig.screenWidth * percentage;
  double responsiveHeight(double percentage) =>
      SizeConfig.screenHeight * percentage;

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Scaffold(
      appBar: CustomAppBar(),
      backgroundColor: AppColors.k_background_white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    height: responsiveHeight(0.07),
                    width: responsiveWidth(0.2),
                    child: Image.asset("assets/img/police_logo.png"),
                  ),
                  Padding(
                    padding: EdgeInsets.only(right: responsiveWidth(0.08)),
                    child: Container(
                      child: Text(
                        "NIIT",
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: AppColors.k_primary_black,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    child: Icon(
                      Icons.notification_add_outlined,
                      color: AppColors.k_primary_black,
                      size: 28,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Container(
                child: Text(
                  "Protégez, servez, avec rapidité.",
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.bold,
                    color: AppColors.k_primary_black,
                  ),
                ),
              ),
              SizedBox(height: responsiveHeight(0.04)),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildCard(
                    context,
                    Icons.document_scanner,
                    'Scanner de Plaques',
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PlateRecognitionScreen(),
                        ),
                      );
                    },
                  ),
                  _buildCard(context, Icons.assignment, 'Interventions', () {
                    // Action à définir
                  }),
                  _buildCard(context, Icons.map, 'Géolocalisation', () {
                    // Action à définir
                  }),

                  _buildCard(context, Icons.report, 'Rapports', () {
                    // Action à définir
                  }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return Card(
      color: AppColors.k_background_white,
      elevation: 8,
      shadowColor: AppColors.k_card_green.withOpacity(0.9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 40, color: AppColors.k_primary_black),
                const SizedBox(height: 16),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.k_primary_black,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
