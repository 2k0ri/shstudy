CREATE TABLE shstudy_auc_topics (
	id INT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
	date DATETIME NOT NULL,
	slug VARCHAR(255) NOT NULL UNIQUE,
	title VARCHAR(255) NOT NULL,
	content TEXT NOT NULL,
	update_at TIMESTAMP NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
	created_at TIMESTAMP NOT NULL default 0,
	deleted_at DATETIME,
	INDEX (date, deleted_at),
	INDEX (slug, deleted_at)
) ENGINE = InnoDB;
-- 更新日時を更新するトリガー
CREATE TRIGGER shstudy_auc_topics_BINS BEFORE INSERT ON shstudy_auc_topics FOR EACH ROW SET NEW.created_at = now();
