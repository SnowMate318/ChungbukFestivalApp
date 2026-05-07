import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

Widget buildEpisodeCard({
  required int index,
  required String imagePath,
  required String episodeNum,
  required String episodeTitle,
  required bool isSelected,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Stack(
      children: [
        // ✅ 배경 이미지
        ClipRRect(
          borderRadius: BorderRadius.circular(12.r),
          child: Image.asset(
            imagePath,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
        ),

        // ✅ 반투명 오버레이 (선택 시 색 변경)
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            color: isSelected
                ? Colors.pink.withOpacity(0.5)
                : Colors.black.withOpacity(0.5),
          ),
        ),

        // ✅ 상단 텍스트 (N편 + 제목)
        Positioned.fill(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                episodeNum,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 6.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 3.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: Text(
                  episodeTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 6.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
