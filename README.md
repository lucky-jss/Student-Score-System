🚀 Student Score System（学生成绩管理系统）
📌 项目简介

本项目是基于 Java + MySQL + Tomcat 开发的学生成绩在线管理系统，实现学生信息管理、成绩录入与查询、数据审计与统计分析等功能。

系统模拟真实教务管理场景，重点优化数据库设计与查询性能，并结合触发器实现“无侵入式数据审计”。

🧱 技术栈
后端：Java（Servlet / JDBC）
数据库：MySQL 8.0
服务器：Tomcat
构建工具：Maven
开发工具：IntelliJ IDEA
⚙️ 核心功能
👨‍🎓 学生管理
学生信息新增 / 删除 / 修改 / 查询
基础信息结构设计（学号、姓名、班级等）
📊 成绩管理
成绩录入与查询
多条件筛选与分页展示
🔍 数据审计系统（重点亮点）
使用 MySQL Trigger 实现无侵入式审计日志
自动记录数据变更（insert / update / delete）
支持后续数据追踪与分析
⚡ 性能优化
基于业务场景设计索引结构
使用 EXPLAIN 分析 SQL 执行计划
优化查询性能与响应速度
📦 数据结构设计
JSON结构化存储变更日志，增强扩展性
设计可扩展数据库表结构
🧠 我的贡献（重点！面试会问）

在四人团队项目中，我主要负责：

🔹 数据库设计与优化（核心表结构设计）
🔹 MySQL Trigger 实现审计日志功能
🔹 JSON结构化日志设计
🔹 索引优化与 SQL 性能分析（EXPLAIN）
🔹 数据库异常问题排查与修复
💡 项目亮点（面试加分）
✔ 实现“无侵入式审计系统”（Trigger替代业务代码记录日志）
✔ 使用 EXPLAIN 对 SQL 进行性能优化分析
✔ 采用 JSON 存储日志，提升扩展能力
✔ 模拟真实企业级数据库设计思路
📂 项目结构（简化）
Student-Score-System
├── src
├── docs
├── sql
├── web
└── pom.xml
🚀 运行方式
git clone https://github.com/lucky-jss/Student-Score-System.git
导入 Maven 项目
配置 Tomcat
导入 MySQL 数据库脚本
启动项目
📌 未来优化方向
引入 Spring Boot 重构后端
增加权限管理系统
接入前端框架（Vue）
优化日志分析系统
