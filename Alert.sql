CREATE TABLE Alert (
    Time      INT          NOT NULL,
    Security  VARCHAR (64) NOT NULL,
    TimeFrame VARCHAR (64) NOT NULL,
    Value     DOUBLE       NOT NULL,
    Factor    DOUBLE       NOT NULL
);
