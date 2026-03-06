from rest_framework import serializers
from django.contrib.auth import get_user_model

User = get_user_model()


class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'role', 'phone']
        read_only_fields = ['id']


class LoginSerializer(serializers.Serializer):
    # Accept email or username for staff login.
    identifier = serializers.CharField()
    password = serializers.CharField()
