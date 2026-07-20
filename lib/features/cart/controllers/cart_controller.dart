import 'dart:async';
import 'package:get/get.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/common/models/module_model.dart';
import 'package:sixam_mart/features/cart/domain/models/cart_model.dart';
import 'package:sixam_mart/features/cart/domain/models/online_cart_model.dart';
import 'package:sixam_mart/features/cart/domain/services/cart_service_interface.dart';
import 'package:sixam_mart/features/checkout/domain/models/place_order_body_model.dart';
import 'package:sixam_mart/features/home/screens/home_screen.dart';
import 'package:sixam_mart/features/item/controllers/item_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/date_converter.dart';
import 'package:sixam_mart/helper/module_helper.dart';
import 'package:sixam_mart/helper/price_converter.dart';

class CartController extends GetxController implements GetxService {
  final CartServiceInterface cartServiceInterface;

  CartController({required this.cartServiceInterface});

  List<CartModel> _cartList = [];
  List<CartModel> get cartList => _cartList;

  // Debounced-sync state for the shared +/- quantity controls. Rapid taps update
  // the quantity instantly (optimistically) and are coalesced into a single
  // backend update per cart line once the taps settle, so concurrent online
  // updates + full-cart refetches can no longer race and revert the number.
  final Map<int, Timer> _quantitySyncTimers = {};
  final Map<int, int> _pendingQuantities = {};

  double _subTotal = 0;
  double get subTotal => _subTotal;

  double _itemPrice = 0;
  double get itemPrice => _itemPrice;

  double _itemDiscountPrice = 0;
  double get itemDiscountPrice => _itemDiscountPrice;

  double _addOns = 0;
  double get addOns => _addOns;

  double _variationPrice = 0;
  double get variationPrice => _variationPrice;

  List<List<AddOns>> _addOnsList = [];
  List<List<AddOns>> get addOnsList => _addOnsList;

  List<bool> _availableList = [];
  List<bool> get availableList => _availableList;

  List<String> notAvailableList = ['Remove it from my cart', 'I’ll wait until it’s restocked', 'Please cancel the order', 'Call me ASAP', 'Notify me when it’s back'];
  bool _addCutlery = false;
  bool get addCutlery => _addCutlery;

  int _notAvailableIndex = -1;
  int get notAvailableIndex => _notAvailableIndex;

  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _needExtraPackage = true;
  bool get needExtraPackage => _needExtraPackage;

  bool _isExpanded = true;
  bool get isExpanded => _isExpanded;

  int? _directAddCartItemIndex = -1;
  int? get directAddCartItemIndex => _directAddCartItemIndex;

  void setDirectlyAddToCartIndex(int? index) {
    _directAddCartItemIndex = index;
  }

  void toggleExtraPackage({bool willUpdate = true}) {
    _needExtraPackage = !_needExtraPackage;
    if(willUpdate) {
      update();
    }
  }

  void setAvailableIndex(int index, {bool willUpdate = true}) {
    _notAvailableIndex = cartServiceInterface.availableSelectedIndex(_notAvailableIndex, index);
    if(willUpdate) {
      update();
    }
  }

  void updateCutlery({bool willUpdate = true}){
    _addCutlery = !_addCutlery;
    if(willUpdate) {
      update();
    }
  }

  Future<void> forcefullySetModule(int moduleId) async {
    ModuleModel? module = cartServiceInterface.forcefullySetModule(Get.find<SplashController>().module, Get.find<SplashController>().moduleList, moduleId);
    if(module != null) {
      await Get.find<SplashController>().setModule(module);
      HomeScreen.loadData(true);
    }
  }

  double calculationCart() {
    _addOnsList = [];
    _availableList = [];
    _itemPrice = 0;
    _itemDiscountPrice = 0;
    _addOns = 0;
    _variationPrice = 0;
    bool isFoodVariation = false;
    double variationWithoutDiscountPrice = 0;
    bool haveVariation = false;
    for (var cartModel in cartList) {

      isFoodVariation = ModuleHelper.getModuleConfig(cartModel.item!.moduleType).newVariation!;
      double? discount = cartModel.item!.discount;
      String? discountType = cartModel.item!.discountType;

      List<AddOns> addOnList = cartServiceInterface.prepareAddonList(cartModel);

      _addOnsList.add(addOnList);
      _availableList.add(DateConverter.isAvailable(cartModel.item!.availableTimeStarts, cartModel.item!.availableTimeEnds));

      _addOns = cartServiceInterface.calculateAddonPrice(_addOns, addOnList, cartModel);

      _variationPrice = cartServiceInterface.calculateVariationPrice(isFoodVariation, cartModel, discount, discountType, _variationPrice);

      variationWithoutDiscountPrice = cartServiceInterface.calculateVariationWithoutDiscountPrice(isFoodVariation, cartModel, variationWithoutDiscountPrice);
      haveVariation = cartServiceInterface.checkVariation(isFoodVariation, cartModel);

      double price = haveVariation ? variationWithoutDiscountPrice : (cartModel.item!.price! * cartModel.quantity!);
      double discountPrice = haveVariation ? (variationWithoutDiscountPrice - _variationPrice)
          : (price - (PriceConverter.convertWithDiscount(cartModel.item!.price!, discount, discountType)! * cartModel.quantity!));

      _itemPrice = _itemPrice + price;
      _itemDiscountPrice = _itemDiscountPrice + discountPrice;

      haveVariation = false;
    }
    if(isFoodVariation){
      _itemDiscountPrice = _itemDiscountPrice + (variationWithoutDiscountPrice - _variationPrice);
      _variationPrice =  variationWithoutDiscountPrice;
      _subTotal = (_itemPrice - _itemDiscountPrice) + _addOns + _variationPrice;
    } else {
      _subTotal = (_itemPrice - _itemDiscountPrice);
    }

    return _subTotal;
  }

  Future<void> addToCart(CartModel cartModel, int? index) async {
    if(index != null && index != -1) {
      _cartList.replaceRange(index, index+1, [cartModel]);
    }else {
      _cartList.add(cartModel);
    }
    Get.find<ItemController>().setExistInCart(cartModel.item, null, notify: true);
    await cartServiceInterface.addSharedPrefCartList(_cartList);

    calculationCart();
    update();
  }

  int? getCartId(int cartIndex) {
    return cartServiceInterface.getCartId(cartIndex, _cartList);
  }

  Future<void> setQuantity(bool isIncrement, int cartIndex, int? stock, int ? quantityLimit) async {
    // Update the quantity locally and refresh the UI immediately so +/- feels
    // instant. The backend sync is debounced below.
    _cartList[cartIndex].quantity = await cartServiceInterface.decideItemQuantity(isIncrement, _cartList, cartIndex, stock, quantityLimit, Get.find<SplashController>().configModel!.moduleConfig!.module!.stock!);

    int cartId = _cartList[cartIndex].id!;
    _pendingQuantities[cartId] = _cartList[cartIndex].quantity!;

    if(ModuleHelper.getModuleConfig(_cartList[cartIndex].item!.moduleType).newVariation!) {
     await Get.find<ItemController>().setExistInCart(_cartList[cartIndex].item, null, notify: true);
    }
    calculationCart();
    update();

    _scheduleQuantitySync(cartId);
  }

  // Debounce the backend quantity update: rapid +/- taps only trigger ONE online
  // update carrying the final quantity, once the taps settle (500ms). This stops
  // the concurrent updates + refetches that previously reverted the number.
  void _scheduleQuantitySync(int cartId) {
    _quantitySyncTimers[cartId]?.cancel();
    _quantitySyncTimers[cartId] = Timer(const Duration(milliseconds: 500), () async {
      _quantitySyncTimers.remove(cartId);
      int index = _cartList.indexWhere((cart) => cart.id == cartId);
      if(index == -1) {
        _pendingQuantities.remove(cartId);
        return;
      }
      int quantity = _pendingQuantities[cartId] ?? _cartList[index].quantity!;
      double discountedPrice = await cartServiceInterface.calculateDiscountedPrice(_cartList[index], quantity, ModuleHelper.getModuleConfig(_cartList[index].item!.moduleType).newVariation!);
      await updateCartQuantityOnline(cartId, discountedPrice, quantity);
      // Only clear the pending marker if no newer tap arrived while syncing.
      if(_pendingQuantities[cartId] == quantity) {
        _pendingQuantities.remove(cartId);
      }
    });
  }

  Future<void> removeFromCart(int index, {Item? item}) async {
    int cartId = _cartList[index].id!;
    // Cancel any pending debounced quantity sync for this line before removing it.
    _quantitySyncTimers[cartId]?.cancel();
    _quantitySyncTimers.remove(cartId);
    _pendingQuantities.remove(cartId);
    _cartList.removeAt(index);
    update();
    Get.find<ItemController>().cartIndexSet();
    await removeCartItemOnline(cartId, item: item);
    if(Get.find<ItemController>().item != null) {
      Get.find<ItemController>().cartIndexSet();
    }

  }

  Future<void> clearCartList({bool canRemoveOnline = true}) async {
    _cartList = [];
    if((AuthHelper.isLoggedIn() || AuthHelper.isGuestLoggedIn()) && (ModuleHelper.getModule() != null || ModuleHelper.getCacheModule() != null) && canRemoveOnline) {
      clearCartOnline();
    }
  }

  int isExistInCart(int? itemID, String variationType, bool isUpdate, int? cartIndex) {
    return cartServiceInterface.isExistInCart(_cartList, itemID, variationType, isUpdate, cartIndex);
  }

  bool existAnotherStoreItem(int? storeID, int? moduleId) {
    return cartServiceInterface.existAnotherStoreItem(storeID, moduleId, _cartList);
  }

  void setCurrentIndex(int index, bool notify) {
    _currentIndex = index;
    if(notify) {
      update();
    }
  }

  Future<bool> addToCartOnline(OnlineCart cart) async {
    _isLoading = true;
    bool success = false;
    update();
    List<OnlineCartModel>? onlineCartList = await cartServiceInterface.addToCartOnline(cart);
    if(onlineCartList != null) {
      _cartList = [];
      _cartList.addAll(cartServiceInterface.formatOnlineCartToLocalCart(onlineCartModel: onlineCartList));
      calculationCart();
      success = true;
    }
    _isLoading = false;
    update();

    return success;
  }

  Future<bool> updateCartOnline(OnlineCart cart) async {
    _isLoading = true;
    bool success = false;
    update();
    List<OnlineCartModel>? onlineCartList = await cartServiceInterface.updateCartOnline(cart);
    if(onlineCartList != null) {
      _cartList = [];
      _cartList.addAll(cartServiceInterface.formatOnlineCartToLocalCart(onlineCartModel: onlineCartList));
      calculationCart();
      success = true;
    }
    _isLoading = false;
    update();

    return success;
  }

  Future<void> updateCartQuantityOnline(int cartId, double price, int quantity) async {
    _isLoading = true;
    update();
    bool success = await cartServiceInterface.updateCartQuantityOnline(cartId, price, quantity);
    if(success) {
      await getCartDataOnline();
      calculationCart();
      await Future.delayed(const Duration(milliseconds: 200));
    }
    _isLoading = false;
    update();
  }

  Future<void> getCartDataOnline() async {
    if(ModuleHelper.getModule() != null || ModuleHelper.getCacheModule() != null) {
      _isLoading = true;
      List<OnlineCartModel>? onlineCartList = await cartServiceInterface.getCartDataOnline();
      if(onlineCartList != null) {
        _cartList = [];
        _cartList.addAll(cartServiceInterface.formatOnlineCartToLocalCart(onlineCartModel: onlineCartList));
        // Keep any quantity the user just changed that hasn't finished syncing,
        // so an in-flight refetch can't momentarily revert the number.
        if(_pendingQuantities.isNotEmpty) {
          for(int i = 0; i < _cartList.length; i++) {
            int? pending = _pendingQuantities[_cartList[i].id];
            if(pending != null) {
              _cartList[i].quantity = pending;
            }
          }
        }
        calculationCart();
      }
      _isLoading = false;
      update();
    }
  }

  Future<bool> removeCartItemOnline(int cartId, {Item? item}) async {
    _isLoading = true;
    update();
    bool success = await cartServiceInterface.removeCartItemOnline(cartId);
    if(success) {
      await getCartDataOnline();
      if(item != null) {
        Get.find<ItemController>().setExistInCart(item, null, notify: true);
      }
    }
    _isLoading = false;
    update();
    return success;
  }

  Future<bool> clearCartOnline() async {
    _isLoading = true;
    update();
    bool success = await cartServiceInterface.clearCartOnline();
    if(success) {
      getCartDataOnline();
    }
    _isLoading = false;
    update();
    return success;
  }

  int cartQuantity(int itemId) {
    return cartServiceInterface.cartQuantity(itemId, _cartList);
  }

  String cartVariant(int itemId) {
    return cartServiceInterface.cartVariant(itemId, _cartList);
  }

  void setExpanded(bool setExpand) {
    _isExpanded = setExpand;
    update();
  }

}