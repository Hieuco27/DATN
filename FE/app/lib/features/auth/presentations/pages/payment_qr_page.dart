import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/ui/notification_service.dart';
import '../../../../core/services/socket_service.dart';
import '../bloc/profile_bloc.dart';

class PaymentQrPage extends StatefulWidget {
  final int paymentId;
  final int orderCode;
  final int amount;
  final String checkoutUrl;
  final String qrCode;
  final int readerId;

  const PaymentQrPage({
    Key? key,
    required this.paymentId,
    required this.orderCode,
    required this.amount,
    required this.checkoutUrl,
    required this.qrCode,
    required this.readerId,
  }) : super(key: key);

  @override
  State<PaymentQrPage> createState() => _PaymentQrPageState();
}

class _PaymentQrPageState extends State<PaymentQrPage> {
  final SocketService _socketService = SocketService();
  StreamSubscription? _paymentSubscription;
  bool _isCompleted = false;
  bool _socketListenerSetup = false;
  Timer? _paymentCheckTimer;
  bool _isCheckingPayment = false;
  int _manualCheckCount = 0;

  @override
  void initState() {
    super.initState();
    _initSocket();
    _setupSocketListener();
  }

  void _initSocket() {
    try {
      print('═══════════════════════════════════════');
      print('🔌 INITIALIZING SOCKET');
      print('   Reader ID: ${widget.readerId}');
      print('   Payment ID: ${widget.paymentId}');
      print('   Order Code: ${widget.orderCode}');
      print('═══════════════════════════════════════');
      
      // Clear any existing listeners first
      _socketService.off('payment_success');
      
      // Then init socket
      _socketService.initSocket(userId: widget.readerId);
      print('✅ Socket init called for user ${widget.readerId}');
      
      // Wait for socket to connect before proceeding
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          print('🔍 Socket connection check after 2 seconds...');
          print('   Is connected: ${_socketService.isConnected}');
          
          // Try to join room again if not already joined
          if (_socketService.isConnected) {
            print('🔄 Manually joining room again...');
            _socketService.joinUserRoom(widget.readerId);
          }
        }
      });
    } catch (e) {
      print('❌ Socket init error: $e');
      print('   Stack trace: ${StackTrace.current}');
    }
  }

  void _setupSocketListener() {
    if (_socketListenerSetup) {
      print('⚠️ Socket listener already setup, skipping');
      return;
    }

    try {
      print('═══════════════════════════════════════');
      print('🔧 SETTING UP SOCKET LISTENERS');
      print('   Payment ID: ${widget.paymentId}');
      print('   Order Code: ${widget.orderCode}');
      print('═══════════════════════════════════════');
      
      // Listen for room join confirmation (if backend sends it)
      _socketService.on('registered', (data) {
        print('✅ Room join CONFIRMED by server: $data');
      });
      
      _socketService.on('register_success', (data) {
        print('✅ Room join SUCCESS: $data');
      });
      
      // Listen for payment_success event
      _socketService.on('payment_success', (data) async {
        print('═══════════════════════════════════════');
        print('💰 PAYMENT_SUCCESS EVENT RECEIVED!');
        print('   Raw data: $data');
        print('   Data type: ${data.runtimeType}');
        print('═══════════════════════════════════════');
        
        if (!mounted) {
          print('⚠️ Widget not mounted, ignoring event');
          return;
        }
        
        if (_isCompleted) {
          print('⚠️ Payment already completed, ignoring event');
          return;
        }
        
        try {
          // Backend emits 'transactionCode' field, NOT 'orderCode'
          final transactionCode = data?['transactionCode']?.toString();
          final orderCode = data?['orderCode']?.toString();
          final paymentId = data?['paymentId'];
          final currentOrderCode = widget.orderCode.toString();
          
          print('🔍 CHECKING PAYMENT MATCH:');
          print('   Expected orderCode: $currentOrderCode');
          print('   Received transactionCode: $transactionCode');
          print('   Received orderCode: $orderCode');
          print('   Received paymentId: $paymentId');
          print('   Widget paymentId: ${widget.paymentId}');
          
          // Match by transactionCode OR orderCode OR paymentId
          bool isMatch = false;
          String matchReason = '';
          
          if (transactionCode != null && transactionCode == currentOrderCode) {
            isMatch = true;
            matchReason = 'transactionCode matches';
          } else if (orderCode != null && orderCode == currentOrderCode) {
            isMatch = true;
            matchReason = 'orderCode matches';
          } else if (paymentId != null && paymentId == widget.paymentId) {
            isMatch = true;
            matchReason = 'paymentId matches';
          }
          
          if (isMatch) {
            print('✅ PAYMENT MATCHES! Reason: $matchReason');
            print('   Processing payment success...');
            await _handlePaymentSuccess(data);
          } else {
            print('❌ PAYMENT DOES NOT MATCH!');
            print('   This event is for a different payment');
          }
        } catch (e) {
          print('❌ Error processing payment_success: $e');
          print('   Stack: ${StackTrace.current}');
        }
      });

      _socketListenerSetup = true;
      print('✅ Socket listener setup complete');
      print('📡 Listening for: payment_success');
      print('📡 Waiting for transactionCode: ${widget.orderCode}');
      print('═══════════════════════════════════════');
      
      // Note: Polling is disabled because checkPaymentStatus API doesn't support
      // filtering by orderCode, which would cause false positives from old payments
      // We rely solely on socket events for real-time payment detection
    } catch (e) {
      print('❌ Socket listener setup error: $e');
    }
  }

  Future<void> _handlePaymentSuccess([Map<String, dynamic>? data]) async {
    if (_isCompleted) {
      print('⚠️ Payment already completed, ignoring duplicate call');
      return;
    }
    
    if (!mounted) {
      print('⚠️ Widget not mounted, cannot handle payment success');
      return;
    }

    print('🎉 ========================================');
    print('🎉 HANDLING PAYMENT SUCCESS');
    print('🎉 Payment ID: ${widget.paymentId}');
    print('🎉 Order Code: ${widget.orderCode}');
    print('🎉 ========================================');

    try {
      setState(() {
        _isCompleted = true;
      });

      NotificationService.showSuccess(
        context,
        message: 'Thanh toán thành công! Số dư đã được cập nhật.',
      );

      // Reload profile
      context.read<ProfileBloc>().add(ProfileLoadRequested());

      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        print('✅ Navigating back to profile page...');
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      print('❌ Error handling payment success: $e');
    }
  }

  @override
  void dispose() {
    _paymentCheckTimer?.cancel();
    _socketService.off('payment_success');
    _paymentSubscription?.cancel();
    super.dispose();
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    NotificationService.showSuccess(
      context,
      message: 'Đã sao chép vào clipboard',
    );
  }

  Future<void> _openInBrowser() async {
    try {
      final uri = Uri.parse(widget.checkoutUrl);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        NotificationService.showError(
          context,
          message: 'Không thể mở trình duyệt',
        );
      }
    }
  }

  Future<void> _manualCheckPayment() async {
    if (_isCompleted || _isCheckingPayment) return;

    setState(() {
      _isCheckingPayment = true;
      _manualCheckCount++;
    });

    print('🔍 Manual payment check #$_manualCheckCount for order ${widget.orderCode}');

    try {
      // Reload profile to get latest member card data
      context.read<ProfileBloc>().add(ProfileLoadRequested());
      
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        NotificationService.showInfo(
          context,
          message: 'Đã cập nhật trạng thái. Nếu đã thanh toán thành công, số dư sẽ được cập nhật.',
        );

        // Check if we should close (assume success after manual check)
        await Future.delayed(const Duration(seconds: 1));
        
        if (mounted && _manualCheckCount >= 2) {
          // After 2 manual checks, assume payment might be successful
          final shouldClose = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Đóng trang thanh toán?'),
              content: const Text(
                'Đã kiểm tra nhiều lần. Bạn có muốn đóng trang này và quay về?\n\n'
                'Nếu đã thanh toán thành công, số dư sẽ được cập nhật tự động.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Tiếp tục chờ'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF667eea),
                  ),
                  child: const Text('Đóng và quay về'),
                ),
              ],
            ),
          );

          if (shouldClose == true && mounted) {
            Navigator.of(context).pop(false);
          }
        }
      }
    } catch (e) {
      print('❌ Manual check error: $e');
      if (mounted) {
        NotificationService.showError(
          context,
          message: 'Không thể kiểm tra. Vui lòng thử lại.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingPayment = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Show confirmation dialog before leaving
        if (_isCompleted) return true;
        
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Hủy thanh toán?'),
            content: const Text(
              'Bạn có chắc muốn hủy giao dịch này không?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Tiếp tục thanh toán'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Hủy'),
              ),
            ],
          ),
        );
        
        return shouldPop ?? false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: const Color(0xFF667eea),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Row(
            children: const [
              SizedBox(width: 8),
              Text(
                'Thanh toán thẻ thư viên',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        body: _isCompleted
            ? _buildSuccessView()
            : _buildPaymentView(),
      ),
    );
  }

  Widget _buildSuccessView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle,
              color: Colors.green.shade600,
              size: 60,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Thanh toán thành công!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.green.shade700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Đang cập nhật số dư...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Info banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Vui lòng quét mã QR hoặc mở link thanh toán để hoàn tất',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.blue.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Amount display
          Text(
            'Số tiền thanh toán',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.amount.toStringAsFixed(0)} đ',
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: Color(0xFF667eea),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // QR Code
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade300, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: QrImageView(
              data: widget.qrCode,
              version: QrVersions.auto,
              size: 280,
              backgroundColor: Colors.white,
              errorCorrectionLevel: QrErrorCorrectLevel.H,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Order code
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Mã đơn: ',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  '${widget.orderCode}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => _copyToClipboard('${widget.orderCode}'),
                  child: Icon(
                    Icons.copy,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Open in browser button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _openInBrowser,
              icon: const Icon(Icons.open_in_browser),
              label: const Text(
                'Mở trang thanh toán',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667eea),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Copy link button
          OutlinedButton.icon(
            onPressed: () => _copyToClipboard(widget.checkoutUrl),
            icon: const Icon(Icons.link),
            label: const Text('Sao chép link thanh toán'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF667eea),
              side: const BorderSide(color: Color(0xFF667eea)),
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Manual check button
          TextButton.icon(
            onPressed: _isCheckingPayment ? null : _manualCheckPayment,
            icon: _isCheckingPayment
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh, size: 20),
            label: Text(
              _isCheckingPayment 
                  ? 'Đang kiểm tra...' 
                  : 'Đã thanh toán? Kiểm tra ngay',
              style: const TextStyle(fontSize: 14),
            ),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF667eea),
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 10,
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Waiting indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            // children: [
            //   SizedBox(
            //     width: 16,
            //     height: 16,
            //     child: CircularProgressIndicator(
            //       strokeWidth: 2,
            //       valueColor: AlwaysStoppedAnimation<Color>(
            //         Colors.grey.shade400,
            //       ),
            //     ),
            //   ),
              // const SizedBox(width: 12),
              // Text(
              //   'Đang chờ thanh toán...',
              //   style: TextStyle(
              //     fontSize: 13,
              //     color: Colors.grey[600],
              //   ),
              // ),
            // ],
          ),
        ],
      ),
    );
  }
}
