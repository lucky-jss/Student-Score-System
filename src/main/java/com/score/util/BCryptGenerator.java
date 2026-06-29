package com.score.util;

import org.mindrot.jbcrypt.BCrypt;

public class BCryptGenerator {
    public static void main(String[] args) {
        String password = "123456";
        String hashed = BCrypt.hashpw(password, BCrypt.gensalt());
        System.out.println("明文密码：" + password);
        System.out.println("BCrypt 哈希值：" + hashed);
        System.out.println("哈希长度：" + hashed.length());
    }
}