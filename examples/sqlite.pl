#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';
use POSIX qw(strftime);
use DBI;
use Data::Dumper;

# Database schema

use constant STMT_CREATE_USER => qq(CREATE TABLE IF NOT EXISTS user
                                    (id               INTEGER PRIMARY KEY AUTOINCREMENT ,
                                     inscription_date INTEGER NOT NULL,
                                     email            TEXT    NOT NULL););
use constant STMT_USER_INDEX_1 => 'CREATE INDEX idx_user_inscription_date ON user(inscription_date);';
use constant STMT_USER_INDEX_2 => 'CREATE UNIQUE INDEX idx_user_email ON user(email);';
use constant STMT_CREATE_MESSAGE => qq(CREATE TABLE IF NOT EXISTS message
                                       (id               INTEGER PRIMARY KEY AUTOINCREMENT,
                                        fk_user_id       INTEGER NOT NULL,
                                        texte            TEXT    NOT NULL,
                                        FOREIGN KEY(fk_user_id) REFERENCES user(id)););

# Requests

use constant STMT_INSERT_USER => 'INSERT INTO user (inscription_date, email) VALUES (strftime("%s", ?), ?);';
use constant STMT_SELECT_USER => 'SELECT * FROM user WHERE id=?;';
use constant STMT_UPDATE_USER_DATE_INSCRIPTION => 'UPDATE user SET inscription_date=strftime("%s", ?) WHERE id=?;';
use constant STMT_UPDATE_USER_EMAIL => 'UPDATE user SET email=? WHERE id=?;';

# Configuration

use constant DB_PATH => 'my-db.sqlite';
use constant USER_COUNT => 10;

# Create the database

my $dbh;
my $dsn = sprintf("DBI:SQLite:dbname=%s", &DB_PATH);
unlink(&DB_PATH);
eval { $dbh = DBI->connect($dsn, '', '', { RaiseError => 1, PrintError => 0, ChopBlanks => 1 }) };
if (defined($@) && length("$@") > 0) {
    printf("Error while connecting to database \"%s\": %s", &DB_PATH, "$@");
    exit(1);
}

my @stmts = (&STMT_CREATE_USER, &STMT_USER_INDEX_1, &STMT_USER_INDEX_2, &STMT_CREATE_MESSAGE);
foreach my $stmt (@stmts) {
    printf("Execute\n\n%s\n\n", $stmt);
    eval { $dbh->do($stmt) };
    if (defined($@) && length("$@") > 0) {
        printf("Error while executing SQL request: %s", "$@");
        $dbh->disconnect();
        exit(1);
    }
}

# Insert data into the database

my $start_date = time();
my @user_ids = ();
for (my $i=0; $i<&USER_COUNT; $i++) {
    my $count;

    # WARNING: the format of a date must be "%Y-%m-%d %H:%M:%S" !!!
    my $inscription_date = strftime('%Y-%m-%d %H:%M:%S', localtime($start_date+$i));
    my $email = sprintf('user_%d@test.com', $i);
    printf("Insert user \"%s\" (date: \"%s\")\n", $email, $inscription_date);
    my $sth = $dbh->prepare(&STMT_INSERT_USER);

    eval {
        $count = $sth->execute($inscription_date, $email);
    };
    if (defined($@) && length("$@") > 0) {
        printf("Error while executing SQL request (%s)", DBI::errstr);
        $dbh->disconnect();
        exit(1);
    }

    my $user_id = $dbh->last_insert_id;
    push(@user_ids, $user_id);
    printf("Number of affected rows: %s\n", $count); # no rows: $count = "0E0"
    printf("Last inserted ID: %d\n", $user_id);
}

# Select and update

foreach my $user_id (@user_ids) {
    my $sth;
    my $count;

    # Select
    $sth = $dbh->prepare(&STMT_SELECT_USER);
    eval {
        $sth->execute($user_id);
    };
    if (defined($@) && length("$@") > 0) {
        printf("Error while executing SQL request (%s)", DBI::errstr);
        $dbh->disconnect();
        exit(1);
    }

    my $row = $sth->fetchrow_hashref();
    if (! defined($row)) {
        printf("Unexpected result. The SELECT should return data!\n");
        $dbh->disconnect();
        exit(1);
    }

    # First update
    my $inscription_date = $row->{inscription_date};
    $inscription_date = strftime('%Y-%m-%d %H:%M:%S', localtime($inscription_date+10));
    printf("Update user \"%s\" (set new date: \"%s\")\n", $row->{email}, $inscription_date);
    $sth = $dbh->prepare(&STMT_UPDATE_USER_DATE_INSCRIPTION);
    eval {
        $count = $sth->execute($inscription_date, $user_id);
    };
    if (defined($@) && length("$@") > 0) {
        printf("Error while executing SQL request (%s)", DBI::errstr);
        $dbh->disconnect();
        exit(1);
    }

    printf("Number of affected rows: %s\n", $count); # no rows: $count = "0E0"

    # Second update
    $sth = $dbh->prepare(&STMT_UPDATE_USER_EMAIL);
    eval {
        $count = $sth->execute(sprintf('toto_%d@toto.com', $user_id), $user_id);
    };
    if (defined($@) && length("$@") > 0) {
        printf("Error while executing SQL request (%s)", DBI::errstr);
        $dbh->disconnect();
        exit(1);
    }
    printf("Number of affected rows: %s\n", $count); # no rows: $count = "0E0"
}

# Add messages

foreach my $user_id (@user_ids) {


}




$dbh->disconnect();
