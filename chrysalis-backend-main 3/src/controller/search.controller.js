const searchService = require('../services/search.service');

exports.search = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { query, page, limit } = req.query;

    const result = await searchService.search(userId, { query, page, limit });

    res.status(200).json(result);
  } catch (err) {
    console.error(err);
    if (err.status) {
      return res.status(err.status).json({
        success: false,
        message: err.message,
      });
    }
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

exports.addRecentSearch = async (req, res) => {
  try {
    const userId = req.user.id;
    const { groupId } = req.body;

    const result = await searchService.addRecentSearch(userId, groupId);

    res.status(201).json(result);
  } catch (err) {
    console.error(err);
    res.status(err.status || 500).json({
      success: false,
      message: err.message || 'Server error',
    });
  }
};

exports.getRecentSearches = async (req, res) => {
  try {
    const userId = req.user.id;
    const { limit } = req.query;

    const result = await searchService.getRecentSearches(
      userId,
      parseInt(limit) || 10,
    );

    res.status(200).json(result);
  } catch (err) {
    console.error(err);
    res.status(err.status || 500).json({
      success: false,
      message: err.message || 'Server error',
    });
  }
};
