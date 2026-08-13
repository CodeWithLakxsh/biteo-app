import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/home_providers.dart';

// ================= PROVIDER =================
final searchQueryProvider =
    NotifierProvider<SearchQueryNotifier, String>(
  SearchQueryNotifier.new,
);

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String value) => state = value;
  void clear() => state = '';
}

// ================= SCREEN =================
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  // 🔥 ZOMATO-STYLE DISH LIST
  final List<String> popularDishes = [
    // --- Burgers & Sandwiches ---
    'Burger', 'Cheeseburger', 'Chicken Burger', 'Veg Burger', 'Paneer Burger', 
    'Aloo Tikki Burger', 'Mutton Burger', 'Fish Burger', 'Double Cheeseburger',
    'Sandwich', 'Grilled Sandwich', 'Club Sandwich', 'Veg Sandwich', 'Chicken Sandwich',
    'Cheese Sandwich', 'Paneer Tikka Sandwich', 'Bombay Sandwich', 'Spinach Corn Sandwich',

    // --- Pizzas & Italian ---
    'Pizza', 'Margherita Pizza', 'Pepperoni Pizza', 'Farmhouse Pizza', 'Veg Supreme Pizza',
    'Paneer Makhani Pizza', 'Chicken Tikka Pizza', 'Tandoori Chicken Pizza', 'Cheese Burst Pizza',
    'Pasta', 'White Sauce Pasta', 'Red Sauce Pasta', 'Arrabbiata Pasta', 'Alfredo Pasta',
    'Macaroni', 'Mac and Cheese', 'Lasagna', 'Ravioli', 'Garlic Bread', 'Cheese Garlic Bread',
    'Stuffed Garlic Bread', 'Risotto', 'Bruschetta',

    // --- North Indian & Mughlai Main Course ---
    'Paneer Butter Masala', 'Kadai Paneer', 'Shahi Paneer', 'Palak Paneer', 'Matar Paneer',
    'Paneer Tikka Masala', 'Paneer Bhurji', 'Paneer Lababdar', 'Malai Kofta', 'Mix Veg',
    'Dal Makhani', 'Dal Tadka', 'Dal Fry', 'Chana Masala', 'Pindi Chole', 'Rajma Masala',
    'Aloo Gobi', 'Jeera Aloo', 'Dum Aloo', 'Bhindi Masala', 'Baingan Bharta', 'Mushroom Masala',
    'Butter Chicken', 'Kadai Chicken', 'Chicken Curry', 'Chicken Tikka Masala', 'Chicken Korma',
    'Chicken Do Pyaza', 'Chicken Changezi', 'Mutton Rogan Josh', 'Mutton Curry', 'Mutton Korma',
    'Mutton Rara', 'Keema Matar', 'Egg Curry', 'Egg Bhurji', 'Fish Curry', 'Prawn Curry',

    // --- Indian Breads (Roti & Paratha) ---
    'Naan', 'Butter Naan', 'Garlic Naan', 'Cheese Naan', 'Tandoori Roti', 'Butter Roti',
    'Rumali Roti', 'Missi Roti', 'Lachha Paratha', 'Pudina Paratha', 'Aloo Paratha',
    'Paneer Paratha', 'Gobi Paratha', 'Mix Paratha', 'Onion Paratha', 'Keema Naan',
    'Kulcha', 'Amritsari Kulcha', 'Onion Kulcha', 'Paneer Kulcha', 'Bhature', 'Puri',

    // --- Biryani & Rice ---
    'Biryani', 'Chicken Biryani', 'Mutton Biryani', 'Veg Biryani', 'Paneer Biryani',
    'Hyderabadi Biryani', 'Lucknowi Biryani', 'Kolkata Biryani', 'Egg Biryani', 'Prawn Biryani',
    'Fried Rice', 'Veg Fried Rice', 'Chicken Fried Rice', 'Egg Fried Rice', 'Schezwan Fried Rice',
    'Pulao', 'Veg Pulao', 'Peas Pulao', 'Kashmiri Pulao', 'Jeera Rice', 'Steamed Rice',
    'Ghee Rice', 'Curd Rice', 'Rajma Chawal', 'Chole Chawal', 'Kadhi Pakora Chawal',

    // --- South Indian ---
    'Dosa', 'Masala Dosa', 'Plain Dosa', 'Rava Dosa', 'Onion Dosa', 'Paneer Dosa',
    'Cheese Dosa', 'Paper Dosa', 'Mysore Masala Dosa', 'Neer Dosa', 'Set Dosa',
    'Idli', 'Sambar Idli', 'Rava Idli', 'Thatte Idli', 'Podi Idli', 'Mini Idli',
    'Vada', 'Medu Vada', 'Sambar Vada', 'Rasa Vada', 'Dal Vada',
    'Uttappam', 'Onion Uttappam', 'Tomato Uttappam', 'Mix Veg Uttappam',
    'Upma', 'Poha', 'Pongal', 'Lemon Rice', 'Tamarind Rice', 'Bisi Bele Bath',
    'Appam', 'Malabar Parotta', 'Chicken Chettinad', 'Fish Fry',

    // --- Street Food & Chaat ---
    'Chole Bhature', 'Pav Bhaji', 'Vada Pav', 'Misal Pav', 'Dabeli', 'Kachori',
    'Samosa', 'Punjabi Samosa', 'Poha Samosa', 'Pani Puri', 'Golgappa', 'Puchka',
    'Bhel Puri', 'Sev Puri', 'Papdi Chaat', 'Aloo Tikki Chaat', 'Raj Kachori',
    'Dahi Bhalla', 'Dahi Puri', 'Basket Chaat', 'Aloo Chaat', 'Samosa Chaat',
    'Ram Ladoo', 'Jhalmuri', 'Mirchi Bajji', 'Pakora', 'Bread Pakora', 'Onion Pakoda',

    // --- Indo-Chinese & Asian ---
    'Momos', 'Veg Momos', 'Chicken Momos', 'Paneer Momos', 'Fried Momos', 'Kurkure Momos',
    'Tandoori Momos', 'Chilli Momos', 'Pan Fried Momos', 'Soup Momos',
    'Noodles', 'Hakka Noodles', 'Chilli Garlic Noodles', 'Schezwan Noodles', 'Pan Fried Noodles',
    'Chowmein', 'Veg Chowmein', 'Chicken Chowmein',
    'Manchurian', 'Veg Manchurian', 'Gobi Manchurian', 'Chicken Manchurian',
    'Chilli Paneer', 'Chilli Chicken', 'Chilli Potato', 'Honey Chilli Potato',
    'Spring Rolls', 'Veg Spring Roll', 'Chicken Spring Roll',
    'Crispy Corn', 'Drums of Heaven', 'Chicken Lollipop', 'Dragon Chicken',
    'Sushi', 'Veg Sushi', 'Chicken Sushi', 'California Roll', 'Dimsum', 'Bao',
    'Pad Thai', 'Thai Green Curry', 'Thai Red Curry', 'Ramen', 'Khao Suey', 'Thukpa',

    // --- Rolls & Wraps ---
    'Rolls', 'Kathi Roll', 'Egg Roll', 'Chicken Roll', 'Paneer Roll', 'Veg Roll',
    'Mutton Roll', 'Double Egg Roll', 'Chicken Tikka Roll', 'Shawarma', 'Chicken Shawarma',
    'Paneer Shawarma', 'Wraps', 'Falafel Wrap', 'Burrito', 'Tacos', 'Quesadilla',

    // --- Starters, Kebabs & Barbeque ---
    'Tandoori Chicken', 'Chicken Tikka', 'Afghani Chicken', 'Malai Tikka', 'Reshmi Kebab',
    'Seekh Kebab', 'Mutton Seekh Kebab', 'Chicken Seekh Kebab', 'Galouti Kebab',
    'Hara Bhara Kebab', 'Paneer Tikka', 'Mushroom Tikka', 'Soya Chaap', 'Malai Chaap',
    'Tandoori Chaap', 'Afghani Chaap', 'Fish Tikka', 'Amritsari Fish', 'Prawns Koliwada',
    'Fries', 'French Fries', 'Peri Peri Fries', 'Cheese Fries', 'Loaded Fries',
    'Potato Wedges', 'Onion Rings', 'Cheese Balls', 'Jalapeno Poppers', 'Chicken Wings',
    'Chicken Nuggets', 'Chicken Strips', 'Garlic Breadsticks',

    // --- Desserts & Sweets ---
    'Ice Cream', 'Vanilla Ice Cream', 'Chocolate Ice Cream', 'Butterscotch', 'Strawberry',
    'Mango Ice Cream', 'Sundae', 'Death by Chocolate', 'Cassata', 'Kulfi', 'Falooda',
    'Cake', 'Chocolate Cake', 'Black Forest Cake', 'Red Velvet Cake', 'Pineapple Cake',
    'Truffle Cake', 'Cheesecake', 'Blueberry Cheesecake', 'Bento Cake', 'Cupcake',
    'Brownie', 'Sizzling Brownie', 'Walnut Brownie', 'Fudge', 'Waffles', 'Belgian Waffle',
    'Chocolate Waffle', 'Pancakes', 'Crepes', 'Donut', 'Churros', 'Macarons',
    'Gulab Jamun', 'Rasgulla', 'Rasmalai', 'Jalebi', 'Rabri', 'Moong Dal Halwa',
    'Gajar Ka Halwa', 'Kaju Katli', 'Barfi', 'Ladoo', 'Motichoor Ladoo', 'Mysore Pak',
    'Payasam', 'Kheer', 'Phirni', 'Shahi Tukda', 'Ghevar',

    // --- Beverages ---
    'Coffee', 'Cold Coffee', 'Hot Coffee', 'Espresso', 'Cappuccino', 'Latte', 'Mocha',
    'Frappe', 'Filter Coffee', 'Black Coffee',
    'Tea', 'Chai', 'Masala Chai', 'Green Tea', 'Lemon Tea', 'Iced Tea', 'Peach Iced Tea',
    'Bubble Tea', 'Boba', 'Matcha',
    'Milkshake', 'Chocolate Shake', 'Vanilla Shake', 'Strawberry Shake', 'Oreo Shake',
    'Kitkat Shake', 'Mango Shake', 'Banana Shake', 'Thick Shake',
    'Lassi', 'Sweet Lassi', 'Mango Lassi', 'Salted Lassi', 'Chaas', 'Buttermilk',
    'Fresh Juice', 'Orange Juice', 'Mosambi Juice', 'Pineapple Juice', 'Watermelon Juice',
    'Mixed Fruit Juice', 'Lemonade', 'Nimbu Pani', 'Virgin Mojito', 'Blue Lagoon',
    'Smoothie', 'Berry Smoothie', 'Mango Smoothie', 'Energy Drink',

    // --- Healthy, Salads & Soups ---
    'Salad', 'Green Salad', 'Greek Salad', 'Caesar Salad', 'Chicken Salad', 'Fruit Salad',
    'Sprouts Salad', 'Quinoa Bowl', 'Oatmeal', 'Protein Bowl', 'Keto Bowl',
    'Soup', 'Tomato Soup', 'Sweet Corn Soup', 'Hot and Sour Soup', 'Manchow Soup',
    'Clear Soup', 'Chicken Soup', 'Mushroom Soup', 'Broccoli Soup',

    // --- Meals & Combos ---
    'Thali', 'Veg Thali', 'Non Veg Thali', 'North Indian Thali', 'South Indian Thali',
    'Gujarati Thali', 'Rajasthani Thali', 'Maharashtrian Thali', 'Mini Thali',
    'Happy Meal', 'Combo Meal', 'Executive Lunch',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    final lowerQuery = query.toLowerCase();
    final vendorsAsync = ref.watch(filteredVendorsProvider);

    // sync controller
    if (_searchController.text != query) {
      _searchController.value = TextEditingValue(
        text: query,
        selection: TextSelection.collapsed(offset: query.length),
      );
    }

    final suggestedDishes = lowerQuery.isEmpty
        ? <String>[]
        : popularDishes
            .where((dish) => dish.toLowerCase().contains(lowerQuery))
            .toList();

    return Scaffold(
      backgroundColor: Colors.white,

      // ================= APP BAR =================
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,

        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.black, size: 20),
          onPressed: () => context.pop(),
        ),

        // 🔥 FIXED SEARCH BAR UI
        title: Container(
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.grey100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.grey200),
          ),
          alignment: Alignment.center,
          child: TextField(
            controller: _searchController,
            autofocus: true,
            onChanged: (value) =>
                ref.read(searchQueryProvider.notifier).setQuery(value),
            style: AppTextStyles.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Search for restaurants, dishes...',
              hintStyle: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.grey400),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              suffixIcon: query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        _searchController.clear();
                        ref.read(searchQueryProvider.notifier).clear();
                      },
                    )
                  : null,
            ),
          ),
        ),
      ),

      // ================= BODY =================
      body: lowerQuery.isEmpty
          ? Center(
              child: Text(
                'Start typing to explore food 🔍',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.grey500),
              ),
            )
          : CustomScrollView(
              slivers: [

                // ================= DISHES =================
                if (suggestedDishes.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        'DISHES',
                        style: AppTextStyles.labelLarge
                            .copyWith(color: Colors.grey),
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final dish = suggestedDishes[index];
                        return ListTile(
                          leading: const Icon(Icons.fastfood_rounded,
                              color: AppColors.grey400),
                          title: Text(dish,
                              style: AppTextStyles.titleMedium),
                          onTap: () {
                            HapticFeedback.selectionClick();
                            ref
                                .read(searchQueryProvider.notifier)
                                .setQuery(dish);
                            FocusScope.of(context).unfocus();
                          },
                        );
                      },
                      childCount: suggestedDishes.length,
                    ),
                  ),
                  const SliverToBoxAdapter(child: Divider()),
                ],

                // ================= RESTAURANTS =================
                vendorsAsync.when(
                  loading: () => const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
                  error: (err, _) => const SliverToBoxAdapter(
                    child: Center(child: Text('Error loading restaurants')),
                  ),
                  data: (vendors) {
                    final matchedVendors = vendors.where((v) {
                      final name = v.businessName.toLowerCase();
                      final category = v.category.toLowerCase();
                      return name.contains(lowerQuery) ||
                          category.contains(lowerQuery);
                    }).toList();

                    // 🔥 FIXED LOGIC
                    if (matchedVendors.isEmpty &&
                        suggestedDishes.isEmpty) {
                      return SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Center(
                            child: Text(
                              "No results for '$query' 😕",
                              style: AppTextStyles.bodyMedium,
                            ),
                          ),
                        ),
                      );
                    }

                    if (matchedVendors.isEmpty) {
                      return const SliverToBoxAdapter(child: SizedBox());
                    }

                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final vendor = matchedVendors[index];
                          return ListTile(
                            leading: const Icon(
                              Icons.storefront_rounded,
                              color: AppColors.electricCoral,
                            ),
                            title: Text(vendor.businessName,
                                style: AppTextStyles.titleMedium),
                            subtitle: Text(vendor.category,
                                style: AppTextStyles.bodySmall),
                            onTap: () {
                              context.push(
                                '/vendor/${vendor.id}',
                                extra: vendor,
                              );
                            },
                          );
                        },
                        childCount: matchedVendors.length,
                      ),
                    );
                  },
                ),
              ],
            ),
    );
  }
}