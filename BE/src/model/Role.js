// src/model/Role.js
const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const Role = sequelize.define('Role', {
  roleId: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true, field: 'roleId' },
  name: { type: DataTypes.STRING(100), allowNull: false, field: 'name' },
  deleted: { type: DataTypes.BOOLEAN, allowNull: false, defaultValue: false, field: 'deleted' },
  created_at: { type: DataTypes.DATE, allowNull: false, defaultValue: DataTypes.NOW, field: 'created_at' },
  updated_at: { type: DataTypes.DATE, allowNull: false, defaultValue: DataTypes.NOW, field: 'updated_at' },
}, { tableName: 'Roles', timestamps: false });

module.exports = Role;
