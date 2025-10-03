package com.example.backendextended.service;

import com.example.backendextended.dto.RegisterRequest;
import com.example.backendextended.dto.UserDto;
import com.example.backendextended.entity.User;
import com.example.backendextended.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
public class UserService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    @Transactional
    public UserDto registerUser(RegisterRequest request) {
        log.info("Registering new user with email: {}", request.getEmail());

        if (userRepository.existsByEmailAndIsDeletedFalse(request.getEmail())) {
            throw new RuntimeException("User with this email already exists");
        }

        User user = new User();
        user.setEmail(request.getEmail());
        user.setPassword(passwordEncoder.encode(request.getPassword()));
        user.setIsDeleted(false);

        User savedUser = userRepository.save(user);
        log.info("User registered successfully with id: {}", savedUser.getId());

        return mapToDto(savedUser);
    }

    public Optional<UserDto> findUserById(UUID id) {
        return userRepository.findById(id).map(this::mapToDto);
    }

    public Optional<UserDto> findUserByEmail(String email) {
        return userRepository.findByEmailAndIsDeletedFalse(email).map(this::mapToDto);
    }

    public List<UserDto> findAllUsers() {
        log.info("Fetching all users");
        List<User> users = userRepository.findAll();
        return users.stream()
                .filter(user -> !user.getIsDeleted())
                .map(this::mapToDto)
                .toList();
    }

    @Transactional
    public void deleteUser(UUID id) {
        log.info("Deleting user with id: {}", id);
        User user = userRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("User not found"));

        user.setIsDeleted(true);
        userRepository.save(user);
        log.info("User deleted successfully");
    }

    private UserDto mapToDto(User user) {
        return new UserDto(
                user.getId(),
                user.getEmail(),
                user.getIsDeleted(),
                user.getCreatedAt()
        );
    }
}

