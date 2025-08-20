import 'package:fashionista/data/models/profile/models/user.dart';
import 'package:fashionista/presentation/screens/profile/widgets/profile_info_card_widget.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class UserProfilePage extends StatelessWidget {
  final User user;
  const UserProfilePage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    //final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SingleChildScrollView(
        child: Column(
          children: [
            //personal info
            ProfileInfoCardWidget(
              items: [
                ProfileInfoItem(
                  Icons.person,
                  title: 'Full name',
                  value: user.fullName,
                ),
                ProfileInfoItem(
                  Icons.person_outline_outlined,
                  title: 'User name',
                  value: user.userName,
                ),
              ],
            ),
            const SizedBox(height: 8),
            //contact info
            ProfileInfoCardWidget(
              items: [
                ProfileInfoItem(
                  Icons.phone,
                  title: 'Mobile number',
                  value: user.mobileNumber,
                ),
                ProfileInfoItem(
                  Icons.email,
                  title: 'Email',
                  value: user.email,
                ),
                ProfileInfoItem(
                  Icons.location_city,
                  title: 'Location',
                  value: user.location,
                ),
              ],
            ),
            //demographic info
            const SizedBox(height: 8),
            ProfileInfoCardWidget(
              items: [
                ProfileInfoItem(
                  Icons.female,
                  title: 'Gender',
                  value: user.gender,
                ),
                ProfileInfoItem(
                  Icons.calendar_month,
                  title: 'Date of birth',
                  value: user.dateOfBirth == null
                      ? ''
                      : DateFormat('yyyy-MM-dd').format(user.dateOfBirth!),
                ),
              ],
            ),
            const SizedBox(height: 8),
            //account info
            ProfileInfoCardWidget(
              items: [
                ProfileInfoItem(
                  Icons.account_box,
                  title: 'Account type',
                  value: user.gender,
                ),
                ProfileInfoItem(
                  Icons.calendar_today,
                  title: 'Joined',
                  value: user.joinedDate == null
                      ? ''
                      : DateFormat('yyyy-MM-dd').format(user.joinedDate!),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
