"""
URL configuration for config project.

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/5.2/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
"""
from django.contrib import admin
from django.urls import path
from pages import views

urlpatterns = [
    # Admin
    path('admin/', admin.site.urls),
    
    # ==========================================================================
    # PUBLIC PAGES
    # ==========================================================================
    path('', views.home, name='home'),
    path('about/', views.about, name='about'),
    path('faq/', views.faq, name='faq'),
    path('how-it-works/', views.how_it_works, name='how_it_works'),
    path('contact/', views.contact, name='contact'),
    path('terms/', views.terms, name='terms'),
    path('privacy/', views.privacy, name='privacy'),
    path('newsletter/signup/', views.newsletter_signup, name='newsletter_signup'),
    
    # ==========================================================================
    # AUTHENTICATION
    # ==========================================================================
    path('login/', views.login_view, name='login'),
    path('signup/', views.signup_view, name='signup'),
    path('logout/', views.logout_view, name='logout'),
    path('password-reset/', views.password_reset, name='password_reset'),
    path('password-reset/done/', views.password_reset_done, name='password_reset_done'),
    path('password-reset/<uidb64>/<token>/', views.password_reset_confirm, name='password_reset_confirm'),
    path('password-reset/complete/', views.password_reset_complete, name='password_reset_complete'),
    
    # ==========================================================================
    # WATCHES
    # ==========================================================================
    path('watches/', views.watch_list, name='watch_list'),
    path('watches/<int:watch_id>/', views.watch_detail, name='watch_detail'),
    path('watches/create/', views.watch_create, name='watch_create'),
    path('watches/<int:watch_id>/edit/', views.watch_edit, name='watch_edit'),
    
    # ==========================================================================
    # OFFERS
    # ==========================================================================
    path('offers/', views.my_offers, name='my_offers'),
    path('offers/received/', views.offers_received, name='offers_received'),
    
    # ==========================================================================
    # CART & ORDERS
    # ==========================================================================
    path('cart/', views.cart, name='cart'),
    path('checkout/', views.checkout, name='checkout'),
    path('orders/', views.my_orders, name='my_orders'),
    path('orders/<int:order_id>/', views.order_detail, name='order_detail'),
    
    # ==========================================================================
    # WISHLIST
    # ==========================================================================
    path('wishlist/', views.wishlist, name='wishlist'),
    
    # ==========================================================================
    # DASHBOARDS
    # ==========================================================================
    path('dashboard/', views.buyer_dashboard, name='buyer_dashboard'),
    path('dashboard/seller/', views.seller_dashboard, name='seller_dashboard'),
    path('dashboard/listings/', views.my_listings, name='my_listings'),
    path('dashboard/settings/', views.account_settings, name='account_settings'),
    
    # ==========================================================================
    # MESSAGES & NOTIFICATIONS
    # ==========================================================================
    path('messages/', views.messages_view, name='messages'),
    path('notifications/', views.notifications, name='notifications'),
    path('notifications/settings/', views.notification_settings, name='notification_settings'),
    path('messages/start/<int:user_id>/', views.start_conversation, name='start_conversation'),
    
    # ==========================================================================
    # SELLER PAGES
    # ==========================================================================
    path('seller/<int:seller_id>/', views.seller_profile, name='seller_profile'),
    path('become-seller/', views.seller_register, name='seller_register'),
    
    # ==========================================================================
    # ADMIN PANEL
    # ==========================================================================
    path('panel/', views.admin_dashboard, name='admin_dashboard'),
    path('panel/sellers/', views.admin_seller_onboarding, name='admin_seller_onboarding'),
    path('panel/listings/', views.admin_listings_approval, name='admin_listings_approval'),
    path('panel/delivery/', views.admin_delivery_management, name='admin_delivery_management'),
    
    # ==========================================================================
    # API ENDPOINTS
    # ==========================================================================
    path('api/notifications/<int:notification_id>/read/', views.api_mark_notification_read, name='api_mark_notification_read'),
    path('api/notifications/mark-all-read/', views.api_mark_all_notifications_read, name='api_mark_all_notifications_read'),
]
