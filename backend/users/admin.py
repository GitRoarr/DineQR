from django.contrib import admin
from django.contrib.auth import get_user_model
from django.contrib.auth.admin import UserAdmin as DjangoUserAdmin
from django.utils.translation import gettext_lazy as _

User = get_user_model()


@admin.register(User)
class UserAdmin(DjangoUserAdmin):
    # Display and filtering
    list_display = ['username', 'email', 'role', 'is_active', 'is_staff']
    list_filter = ['role', 'is_staff', 'is_superuser', 'is_active', 'groups']
    search_fields = ['username', 'email']
    ordering = ['username']

    # Fields layout for change view
    fieldsets = (
        (None, {'fields': ('username', 'password')}),
        (_('Personal info'), {
            'fields': ('first_name', 'last_name', 'email', 'phone', 'avatar'),
        }),
        (_('Role'), {'fields': ('role',)}),
        (_('Permissions'), {
            'fields': (
                'is_active', 'is_staff', 'is_superuser',
                'groups', 'user_permissions',
            ),
        }),
        (_('Important dates'), {'fields': ('last_login', 'date_joined')}),
    )

    # Fields layout for add view (includes password1/password2 so Django hashes it)
    add_fieldsets = (
        (None, {
            'classes': ('wide',),
            'fields': (
                'username', 'password1', 'password2',
                'first_name', 'last_name', 'email',
                'phone', 'avatar', 'role',
                'is_active', 'is_staff', 'is_superuser',
                'groups', 'user_permissions',
            ),
        }),
    )
