import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/core/design/app_tokens.dart';
import 'package:quickgrocery/core/navigation/app_page_routes.dart';
import 'package:quickgrocery/core/localization/l10n_extension.dart';

class TitleTile extends StatelessWidget {
  const TitleTile({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.start,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: 17,
              color: AppSurface.of(context).textPrimary,
              letterSpacing: -0.25,
            ),
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.push(context, AppPageRoutes.search());
          },
          style: TextButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
          child: Text(
            context.l10n.see_all,
            style: GoogleFonts.poppins(
              color: AppColor.primary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}
