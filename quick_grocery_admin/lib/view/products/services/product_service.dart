import 'dart:developer';
import 'dart:typed_data';
import 'package:quick_grocery_admin/model/catrgory_model.dart';
import 'package:quick_grocery_admin/model/product_model.dart';
import 'package:quick_grocery_admin/model/vendor_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProductService extends ChangeNotifier {
  Uint8List? imageBytes;
  List<Uint8List> imageBytesList = []; // For multiple images
  List<Uint8List> videoBytesList = []; // For multiple videos
  final ImagePicker _picker = ImagePicker();
  bool isLoading = false;
  bool isTodaysBest = false;
  bool isMostSelling = false;

  String selectedImage = '';
  Future<void> pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      imageBytes = await pickedFile.readAsBytes();
      selectedImage = '';
      notifyListeners();
    }
  }

  Future<void> pickMultipleImages() async {
    final pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      for (var file in pickedFiles) {
        final bytes = await file.readAsBytes();
        imageBytesList.add(bytes);
      }
      notifyListeners();
    }
  }

  Future<void> pickVideo() async {
    final pickedFile = await _picker.pickVideo(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      videoBytesList.add(bytes);
      notifyListeners();
    }
  }

  void removeImage(int index) {
    if (index >= 0 && index < imageBytesList.length) {
      imageBytesList.removeAt(index);
      notifyListeners();
    }
  }

  void removeVideo(int index) {
    if (index >= 0 && index < videoBytesList.length) {
      videoBytesList.removeAt(index);
      notifyListeners();
    }
  }

  List<CategoryModel>? category;
  List<VendorModel>? vendors;
  List<CategoryModel>? categories;
  List<CategoryModel>?
  subCategories; // For subcategories (filtered by main category)
  List<CategoryModel>? allSubCategories; // All subcategories for display
  List<ProductModel>? productsList;
  List<ProductModel>? filteredProductsList;
  String? selectedItem;
  String? selectedSubCategory; // Selected subcategory
  String? selectedVendor;
  String? selectedunit;
  TextEditingController productNamecontroller = TextEditingController();
  TextEditingController mrpcontroller = TextEditingController();
  TextEditingController pricecontroller = TextEditingController();
  TextEditingController descriptioncontroller = TextEditingController();
  TextEditingController unitcontroller = TextEditingController();
  TextEditingController hsnsCode = TextEditingController();

  TextEditingController ceesGSt = TextEditingController();
  TextEditingController stockcontroller = TextEditingController();
  TextEditingController cGstcontroller = TextEditingController();

  TextEditingController cutcontroller = TextEditingController();
  TextEditingController quantitycontroller = TextEditingController();

  TextEditingController categoryController = TextEditingController();
  TextEditingController categoryOrderController = TextEditingController();
  TextEditingController subCategoryController = TextEditingController();
  TextEditingController subCategoryOrderController = TextEditingController();
  String? selectedMainCategoryForSubCategory; // For adding subcategory

  // Edit tracking
  String? editingCategoryId;
  String? editingSubCategoryId;
  String? editingCategoryImage; // Store existing image when editing
  String? editingSubCategoryImage; // Store existing image when editing

  String getVendorIdByShopName(List<VendorModel> vendors, String shopName) {
    VendorModel? vendor = vendors.firstWhere(
      (v) => v.shopName.toLowerCase() == shopName.toLowerCase(),
    );

    return vendor.id;
  }

  List<String> unit = ['kg', 'gm', 'ltr', 'pc', 'ml'];
  void onUnitChanged(String value) {
    selectedunit = value;
    notifyListeners();
  }

  void onCategoryQuaryChange(String query) {
    if (query.isEmpty) {
      filteredProductsList = productsList;
    } else {
      filteredProductsList = productsList
          ?.where(
            (product) =>
                product.category.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();
    }
    notifyListeners();
  }

  void onSearchQuary(String query) {
    if (query.isEmpty) {
      filteredProductsList = productsList;
    } else {
      filteredProductsList = productsList
          ?.where(
            (product) =>
                product.name.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();
    }
    notifyListeners();
  }

  void clear() {
    filteredProductsList = productsList;
    notifyListeners();
  }

  Future<String> uploadImageToStorage(Uint8List imageData) async {
    try {
      isLoading = true;
      notifyListeners();

      Reference storageRef = FirebaseStorage.instance.ref().child(
        'shop_images/${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      UploadTask uploadTask = storageRef.putData(imageData);
      TaskSnapshot taskSnapshot = await uploadTask;

      String downloadUrl = await taskSnapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return '';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<String> uploadVideoToStorage(Uint8List videoData) async {
    try {
      isLoading = true;
      notifyListeners();

      Reference storageRef = FirebaseStorage.instance.ref().child(
        'product_videos/${DateTime.now().millisecondsSinceEpoch}.mp4',
      );

      UploadTask uploadTask = storageRef.putData(videoData);
      TaskSnapshot taskSnapshot = await uploadTask;

      String downloadUrl = await taskSnapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading video: $e');
      return '';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<List<String>> uploadMultipleImages(List<Uint8List> images) async {
    List<String> imageUrls = [];
    for (var imageData in images) {
      String url = await uploadImageToStorage(imageData);
      if (url.isNotEmpty) {
        imageUrls.add(url);
      }
    }
    return imageUrls;
  }

  Future<List<String>> uploadMultipleVideos(List<Uint8List> videos) async {
    List<String> videoUrls = [];
    for (var videoData in videos) {
      String url = await uploadVideoToStorage(videoData);
      if (url.isNotEmpty) {
        videoUrls.add(url);
      }
    }
    return videoUrls;
  }

  Future<void> addProduct(BuildContext context) async {
    if (productNamecontroller.text.isEmpty) {
      showValidationDialog(context, "Product Name cannot be empty.");
    } else if (mrpcontroller.text.isEmpty) {
      showValidationDialog(context, "MRP cannot be empty.");
    } else if (pricecontroller.text.isEmpty) {
      showValidationDialog(context, "Price cannot be empty.");
    } else if (selectedItem == null) {
      showValidationDialog(context, "Category cannot be empty.");
    } else if (selectedunit == null) {
      showValidationDialog(context, "Unit cannot be empty.");
    } else if (descriptioncontroller.text.isEmpty) {
      showValidationDialog(context, "Description cannot be empty.");
    } else if (unitcontroller.text.isEmpty) {
      showValidationDialog(context, "Unit per item cannot be empty.");
    } else if (stockcontroller.text.isEmpty) {
      showValidationDialog(context, "Stock cannot be empty.");
    } else if (quantitycontroller.text.isEmpty) {
      showValidationDialog(context, "Quantity cannot be empty.");
    } else if (selectedVendor == null) {
      showValidationDialog(context, "Vendor cannot be empty.");
    } else if (imageBytes == null) {
      showValidationDialog(context, "Product image cannot be empty.");
    } else {
      String productImage = await uploadImageToStorage(imageBytes!);

      // Upload multiple images
      List<String> imageUrls = [];
      if (imageBytesList.isNotEmpty) {
        imageUrls = await uploadMultipleImages(imageBytesList);
      }

      // Upload multiple videos
      List<String> videoUrls = [];
      if (videoBytesList.isNotEmpty) {
        videoUrls = await uploadMultipleVideos(videoBytesList);
      }

      DocumentReference docRef = await FirebaseFirestore.instance
          .collection('products')
          .add({
            'id': "",
            'name': productNamecontroller.text,
            'image': productImage,
            'createdAt': FieldValue.serverTimestamp(),
            'description': descriptioncontroller.text,
            'category': selectedItem,
            'unit': selectedunit,
            'stock': stockcontroller.text,
            'maxOrder': quantitycontroller.text,
            'price': pricecontroller.text,
            'slashedPrice': mrpcontroller.text,
            'totalSold': 0,
            'vendor_id': getVendorIdByShopName(vendors!, selectedVendor!),
            'is_flash_sale': false,
            'is_active': true,
            'lastEdited': FieldValue.serverTimestamp(),
            'unitPerItem': unitcontroller.text,
            'favorites': [],
            'shop_name': selectedVendor,
            'hsn_code': hsnsCode.text,
            'ces_gst': ceesGSt.text,
            'c_gst': cGstcontroller.text,
            'cut': cutcontroller.text,
            'images': imageUrls,
            'videos': videoUrls,
            if (selectedSubCategory != null) 'subcategory': selectedSubCategory,
          });
      String vendorId = docRef.id;

      await docRef.update({"id": vendorId});
      isLoading = false;
      showSuccessDialog(context);
      resetFields();
      notifyListeners();
    }
  }

  void resetFields() {
    imageBytes = null;
    imageBytesList.clear();
    videoBytesList.clear();
    selectedItem = null;
    selectedSubCategory = null;
    selectedVendor = null;
    selectedunit = null;
    subCategories = null;

    productNamecontroller.clear();
    mrpcontroller.clear();
    pricecontroller.clear();
    descriptioncontroller.clear();
    unitcontroller.clear();
    stockcontroller.clear();
    quantitycontroller.clear();

    notifyListeners();
  }

  Future<List<CategoryModel>?> fetchCategory() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('categories')
          .get();

      category = snapshot.docs.map((doc) {
        return CategoryModel.fromFirestore(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();

      return category;
    } catch (e) {
      log(e.toString());
      return null;
    }
  }

  Future<void> initProduct(ProductModel product) async {
    productNamecontroller.text = product.name;
    pricecontroller.text = product.price;
    mrpcontroller.text = product.slashedPrice;
    mrpcontroller.text = product.slashedPrice;
    selectedItem = product.category;
    selectedunit = product.unit;
    descriptioncontroller.text = product.description;
    unitcontroller.text = product.unitPerItem;
    stockcontroller.text = product.stock;
    quantitycontroller.text = product.maxOrder;
    selectedImage = product.image;
    isMostSelling = product.isMostSelling;
    isTodaysBest = product.isTodaysBest;
    selectedVendor = product.shopName;
  }

  void onMostSellingChange(bool v) async {
    isMostSelling = v;
    notifyListeners();
  }

  void onTodaysBest(bool v) async {
    isTodaysBest = v;
    notifyListeners();
  }

  Future<void> updateProduct(BuildContext context, String id) async {
    // Validation
    if (productNamecontroller.text.isEmpty) {
      showValidationDialog(context, "Product Name cannot be empty.");
      return;
    } else if (mrpcontroller.text.isEmpty) {
      showValidationDialog(context, "MRP cannot be empty.");
      return;
    } else if (pricecontroller.text.isEmpty) {
      showValidationDialog(context, "Price cannot be empty.");
      return;
    } else if (selectedItem == null) {
      showValidationDialog(context, "Category cannot be empty.");
      return;
    } else if (selectedunit == null) {
      showValidationDialog(context, "Unit cannot be empty.");
      return;
    } else if (descriptioncontroller.text.isEmpty) {
      showValidationDialog(context, "Description cannot be empty.");
      return;
    } else if (unitcontroller.text.isEmpty) {
      showValidationDialog(context, "Unit per item cannot be empty.");
      return;
    } else if (stockcontroller.text.isEmpty) {
      showValidationDialog(context, "Stock cannot be empty.");
      return;
    } else if (quantitycontroller.text.isEmpty) {
      showValidationDialog(context, "Quantity cannot be empty.");
      return;
    } else if (selectedVendor == null) {
      showValidationDialog(context, "Vendor cannot be empty.");
      return;
    }

    try {
      isLoading = true;
      notifyListeners();

      Map<String, dynamic> updateData = {
        'name': productNamecontroller.text,
        'description': descriptioncontroller.text,
        'category': selectedItem,
        'unit': selectedunit,
        'stock': stockcontroller.text,
        'maxOrder': quantitycontroller.text,
        'price': pricecontroller.text,
        'slashedPrice': mrpcontroller.text,
        'vendor_id': getVendorIdByShopName(vendors!, selectedVendor!),
        'lastEdited': FieldValue.serverTimestamp(),
        'unitPerItem': unitcontroller.text,
        'shop_name': selectedVendor,
        'is_most_selling': isMostSelling,
        'is_todays_best': isTodaysBest,
        'most_sold': isMostSelling,
        'isAvailable': true,
        'is_active': true,
      };

      // If a new image is selected, upload it
      if (imageBytes != null) {
        String productImage = await uploadImageToStorage(imageBytes!);
        updateData['image'] = productImage;
      }

      // Update the product in Firestore
      await FirebaseFirestore.instance
          .collection('products')
          .doc(id)
          .update(updateData);

      isLoading = false;
      notifyListeners();

      showUpdateSuccessDialog(context);

      // Refresh products list if it exists
      if (productsList != null) {
        await fetchProducts();
      }
    } catch (e) {
      isLoading = false;
      notifyListeners();
      log('Error updating product: $e');
      showValidationDialog(context, "Error updating product: ${e.toString()}");
    }
  }

  Future<List<VendorModel>?> fetchVendors() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('vendors')
        .get();

    vendors = snapshot.docs.map((doc) {
      return VendorModel.fromFirestore(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
    }).toList();
    notifyListeners();
    return vendors;
  }

  void onCategoryChanged(String newValue) async {
    selectedItem = newValue;
    selectedSubCategory = null; // Reset subcategory when main category changes
    // Fetch subcategories for the selected main category
    if (newValue.isNotEmpty) {
      await fetchSubCategories(newValue);
    }
    notifyListeners();
  }

  void onSubCategoryChanged(String? newValue) {
    selectedSubCategory = newValue;
    notifyListeners();
  }

  void onMainCategoryForSubCategoryChanged(String? newValue) {
    selectedMainCategoryForSubCategory = newValue;
    notifyListeners();
  }

  Future<void> fetchSubCategories(String mainCategory) async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('subcategories')
          .where('main_category', isEqualTo: mainCategory)
          .orderBy('order')
          .get();

      subCategories = snapshot.docs.map((doc) {
        return CategoryModel.fromJson(doc.data() as Map<String, dynamic>);
      }).toList();

      notifyListeners();
    } catch (e) {
      log("Error getting subcategories: $e");
      subCategories = [];
      notifyListeners();
    }
  }

  void onVendorChanged(String newValue) {
    selectedVendor = newValue;
    notifyListeners();
  }

  Future<void> fetchProducts() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('products')
          .get();

      productsList = snapshot.docs.map((doc) {
        return ProductModel.fromFirestore(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();

      notifyListeners();
      filteredProductsList = productsList;
    } catch (e) {
      log(e.toString());
    }
  }

  Future<void> getCategories() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('categories')
          .get();

      categories = snapshot.docs.map((doc) {
        return CategoryModel.fromFirestore(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();

      notifyListeners();
    } catch (e) {
      log(e.toString());
    }
  }

  Future<void> getAllSubCategories() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('subcategories')
          .orderBy('order')
          .get();

      allSubCategories = snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Ensure ID is set
        return CategoryModel.fromJson(data);
      }).toList();

      notifyListeners();
    } catch (e) {
      log(e.toString());
      allSubCategories = [];
      notifyListeners();
    }
  }

  void initCategoryForEdit(CategoryModel category) {
    editingCategoryId = category.id;
    categoryController.text = category.name;
    categoryOrderController.text = category.order;
    editingCategoryImage = category.image;
    selectedImage = category.image;
    imageBytes = null;
    notifyListeners();
  }

  void initSubCategoryForEdit(CategoryModel subCategory) {
    editingSubCategoryId = subCategory.id;
    subCategoryController.text = subCategory.name;
    subCategoryOrderController.text = subCategory.order;
    selectedMainCategoryForSubCategory = subCategory.mainCategory;
    editingSubCategoryImage = subCategory.image;
    selectedImage = subCategory.image;
    imageBytes = null;
    notifyListeners();
  }

  void cancelEdit() {
    editingCategoryId = null;
    editingSubCategoryId = null;
    editingCategoryImage = null;
    editingSubCategoryImage = null;
    categoryController.clear();
    categoryOrderController.clear();
    subCategoryController.clear();
    subCategoryOrderController.clear();
    selectedMainCategoryForSubCategory = null;
    imageBytes = null;
    selectedImage = '';
    notifyListeners();
  }

  Future<void> addCategory(BuildContext context) async {
    if (categoryController.text.isEmpty) {
      showValidationDialog(context, "Category Name cannot be empty.");
      return;
    } else if (categoryOrderController.text.isEmpty) {
      showValidationDialog(context, "Category Order Number cannot be empty.");
      return;
    }

    // If editing, call update instead
    if (editingCategoryId != null) {
      await updateCategory(context, editingCategoryId!);
      return;
    }

    // Validation for new category
    if (imageBytes == null) {
      showValidationDialog(context, "Category Image cannot be empty.");
      return;
    }

    try {
      isLoading = true;
      notifyListeners();

      String productImage = await uploadImageToStorage(imageBytes!);
      DocumentReference docRef = await FirebaseFirestore.instance
          .collection('categories')
          .add({
            'id': "",
            'name': categoryController.text,
            'image': productImage,
            'createdAt': FieldValue.serverTimestamp(),
            'order': int.parse(categoryOrderController.text),
          });
      String id = docRef.id;
      await docRef.update({"id": id});

      categoryController.clear();
      categoryOrderController.clear();
      imageBytes = null;
      isLoading = false;
      getCategories();
      notifyListeners();
      showSuccessDialog(context);
    } catch (e) {
      isLoading = false;
      notifyListeners();
      log('Error adding category: $e');
      showValidationDialog(context, "Error adding category: ${e.toString()}");
    }
  }

  Future<void> updateCategory(BuildContext context, String id) async {
    if (categoryController.text.isEmpty) {
      showValidationDialog(context, "Category Name cannot be empty.");
      return;
    } else if (categoryOrderController.text.isEmpty) {
      showValidationDialog(context, "Category Order Number cannot be empty.");
      return;
    }

    try {
      isLoading = true;
      notifyListeners();

      Map<String, dynamic> updateData = {
        'name': categoryController.text,
        'order': int.parse(categoryOrderController.text),
      };

      // If a new image is selected, upload it
      if (imageBytes != null) {
        String productImage = await uploadImageToStorage(imageBytes!);
        updateData['image'] = productImage;
      }

      await FirebaseFirestore.instance
          .collection('categories')
          .doc(id)
          .update(updateData);

      categoryController.clear();
      categoryOrderController.clear();
      imageBytes = null;
      editingCategoryId = null;
      editingCategoryImage = null;
      selectedImage = '';
      isLoading = false;
      getCategories();
      notifyListeners();
      showUpdateSuccessDialog(context);
    } catch (e) {
      isLoading = false;
      notifyListeners();
      log('Error updating category: $e');
      showValidationDialog(context, "Error updating category: ${e.toString()}");
    }
  }

  Future<void> addSubCategory(BuildContext context) async {
    if (subCategoryController.text.isEmpty) {
      showValidationDialog(context, "Subcategory Name cannot be empty.");
      return;
    } else if (subCategoryOrderController.text.isEmpty) {
      showValidationDialog(
        context,
        "Subcategory Order Number cannot be empty.",
      );
      return;
    } else if (selectedMainCategoryForSubCategory == null) {
      showValidationDialog(context, "Please select a main category.");
      return;
    }

    // If editing, call update instead
    if (editingSubCategoryId != null) {
      await updateSubCategory(context, editingSubCategoryId!);
      return;
    }

    // Validation for new subcategory
    if (imageBytes == null) {
      showValidationDialog(context, "Subcategory Image cannot be empty.");
      return;
    }

    try {
      isLoading = true;
      notifyListeners();

      String productImage = await uploadImageToStorage(imageBytes!);
      DocumentReference docRef = await FirebaseFirestore.instance
          .collection('subcategories')
          .add({
            'id': "",
            'name': subCategoryController.text,
            'image': productImage,
            'createdAt': FieldValue.serverTimestamp(),
            'order': int.parse(subCategoryOrderController.text),
            'main_category': selectedMainCategoryForSubCategory,
          });
      String id = docRef.id;
      await docRef.update({"id": id});

      subCategoryController.clear();
      subCategoryOrderController.clear();
      selectedMainCategoryForSubCategory = null;
      imageBytes = null;
      isLoading = false;
      getAllSubCategories(); // Refresh the list
      notifyListeners();
      showSuccessDialog(context);
    } catch (e) {
      isLoading = false;
      notifyListeners();
      log('Error adding subcategory: $e');
      showValidationDialog(
        context,
        "Error adding subcategory: ${e.toString()}",
      );
    }
  }

  Future<void> updateSubCategory(BuildContext context, String id) async {
    if (subCategoryController.text.isEmpty) {
      showValidationDialog(context, "Subcategory Name cannot be empty.");
      return;
    } else if (subCategoryOrderController.text.isEmpty) {
      showValidationDialog(
        context,
        "Subcategory Order Number cannot be empty.",
      );
      return;
    } else if (selectedMainCategoryForSubCategory == null) {
      showValidationDialog(context, "Please select a main category.");
      return;
    }

    try {
      isLoading = true;
      notifyListeners();

      Map<String, dynamic> updateData = {
        'name': subCategoryController.text,
        'order': int.parse(subCategoryOrderController.text),
        'main_category': selectedMainCategoryForSubCategory,
      };

      // If a new image is selected, upload it
      if (imageBytes != null) {
        String productImage = await uploadImageToStorage(imageBytes!);
        updateData['image'] = productImage;
      }

      await FirebaseFirestore.instance
          .collection('subcategories')
          .doc(id)
          .update(updateData);

      subCategoryController.clear();
      subCategoryOrderController.clear();
      selectedMainCategoryForSubCategory = null;
      imageBytes = null;
      editingSubCategoryId = null;
      editingSubCategoryImage = null;
      selectedImage = '';
      isLoading = false;
      getAllSubCategories(); // Refresh the list
      notifyListeners();
      showUpdateSuccessDialog(context);
    } catch (e) {
      isLoading = false;
      notifyListeners();
      log('Error updating subcategory: $e');
      showValidationDialog(
        context,
        "Error updating subcategory: ${e.toString()}",
      );
    }
  }

  void showDeleteSubCategoryDialog(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm Delete"),
          content: const Text(
            "Are you sure you want to delete this subcategory?",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text("No"),
            ),
            TextButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('subcategories')
                    .doc(id)
                    .delete();
                Navigator.of(context).pop(); // Close the dialog
                getAllSubCategories(); // Refresh the list
              },
              child: const Text("Yes"),
            ),
          ],
        );
      },
    );
  }

  void showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text("Success", style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text("Added successfully!"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text("OK", style: TextStyle(color: Colors.blue)),
            ),
          ],
        );
      },
    );
  }

  void showUpdateSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text("Success", style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text("Product updated successfully!"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text("OK", style: TextStyle(color: Colors.blue)),
            ),
          ],
        );
      },
    );
  }

  void showValidationDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15), // Rounded corners
          ),
          backgroundColor: Colors.white,
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
              SizedBox(width: 10),
              Text(
                "Validation Error",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.redAccent,
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: TextStyle(fontSize: 16, color: Colors.black87),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                child: Text("OK", style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        );
      },
    );
  }

  void showDeleteDialog(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm Delete"),
          content: const Text("Are you sure you want to delete this item?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text("No"),
            ),
            TextButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('categories')
                    .doc(id)
                    .delete();
                Navigator.of(context).pop(); // Close the dialog
                // Perform delete action here
                print("Item deleted!");
                getCategories();
              },
              child: const Text("Yes"),
            ),
          ],
        );
      },
    );
  }
}
