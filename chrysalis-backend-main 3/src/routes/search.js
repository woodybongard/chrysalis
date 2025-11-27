// routes/keys.routes.js
const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/auth');
const searchController = require('../controller/search.controller');

router.get('/', authenticate, searchController.search);
router.post('/recent-search', authenticate, searchController.addRecentSearch);
router.get('/recent-search', authenticate, searchController.getRecentSearches);

module.exports = router;
