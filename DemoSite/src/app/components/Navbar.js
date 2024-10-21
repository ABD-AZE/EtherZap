"use client";
import Link from "next/link";
import React, { useEffect, useState } from "react";
import { MdSearch, MdClose, MdSettings } from "react-icons/md";
import { FaAngleRight } from "react-icons/fa";
import { FaAngleDown, FaFaceFrown } from "react-icons/fa6";
import { RiQuestionFill } from "react-icons/ri";
import userData from "@/app/UserData";
import { motion } from "framer-motion";
import { useClickOutside } from "@mantine/hooks";
import { Switch } from "@headlessui/react";
import Swal from "sweetalert2";


const Navbar = () => {
  const [isFocused, setIsFocused] = useState(false);
  const ref = useClickOutside(() => setIsFocused(false));
  const [searchValue, setSearchValue] = useState("");
  const [ProfileMenu, setProfileMenu] = useState(false);
  const [searchedUser, setSearchedUser] = useState(userData);
  const [searchPanel, setSearchPanel] = useState(false);
  const [adsEnabled, setAdsEnabled] = useState(true); 

  const handleToggle = () => {
    if (!adsEnabled) {
      setAdsEnabled(true);
    } else {
      Swal.fire({
        title: 'Disable Ads?',
        text: "By disabling ads, you'll need to pay for gas fees. Do you want to proceed?",
        icon: 'warning',
        showCancelButton: true,
        confirmButtonColor: '#3085d6',
        cancelButtonColor: '#d33',
        confirmButtonText: 'Yes, proceed with transaction',
        cancelButtonText: 'Cancel',
      }).then((result) => {
        if (result.isConfirmed) {
          Swal.fire(
            'Transaction Initiated',
            'You will be redirected to complete the transaction.',
            'success'
          );
          setAdsEnabled(false); 
        }
      });
    }
  };

  const searchUsers = (value) => {
    let searchedUser = userData.filter((user) => {
      return user.name.toLowerCase().includes(value.toLowerCase());
    });
    setSearchedUser(
      searchedUser.length === 0 ? [{ error: "User Not Found" }] : searchedUser
    );
  };

  useEffect(() => {
    window.addEventListener("click", (e) => {
      if (!e.target.closest(".userProfile")) {
        setProfileMenu(false);
      }
    });
  }, []);

  return (
    <>
      <div className="inNavbar">
        <Link href={"/"} className="inLogo">
          SocialApp
        </Link>
        <div
          ref={ref}
          className={`inSearch ${isFocused ? "inSearchFocused" : ""}`}
        >
          <div className="inSearchWrapper">
            <div className="inSearchIcon">
              <MdSearch className="inIcon" />
            </div>
            <input
              type="text"
              onClick={() => setIsFocused(true)}
              placeholder="Search"
              value={searchValue}
              onFocus={() => setIsFocused(true)}
              onChange={(e) => setSearchValue(e.target.value)}
              onKeyUp={(e) => searchUsers(e.target.value)}
            />
            <div
              className={`inSearchCloseBtn ${
                searchValue.length >= 1 ? "inSearchCloseBtnActive" : ""
              }`}
            >
              <MdClose
                className="inIcon"
                onClick={() => {
                  setSearchValue("");
                  setIsFocused(false);
                  setTimeout(() => {
                    setSearchedUser(userData);
                  }, 300);
                }}
              />
            </div>
          </div>

          <motion.div
            className="searchResult"
            initial={{ y: 30, opacity: 0, pointerEvents: "none" }}
            animate={{
              y: isFocused ? 0 : 30,
              opacity: isFocused ? 1 : 0,
              pointerEvents: isFocused ? "auto" : "none",
            }}
          >
            {isFocused &&
              searchedUser.map((user, index) => {
                if (user.error) {
                  return (
                    <div className="noUserFound" key={index}>
                      <FaFaceFrown />
                      <h3>Sorry {user.error}</h3>
                    </div>
                  );
                } else {
                  return (
                    <div
                      key={index}
                      className="searchResultItem"
                      onClick={() => setSearchValue(user.name)}
                    >
                      <div className="userImage">
                        <img src={`${user.profilePic}`} alt="" />
                      </div>
                      <h3>{user.name}</h3>
                    </div>
                  );
                }
              })}
          </motion.div>
        </div>
        <div className="inNavRightOptions">
          <div className="mobileSearchBtn" onClick={() => setSearchPanel(true)}>
            <MdSearch />
          </div>
          <label className="inBtn" htmlFor="createNewPost">
            Post
          </label>

          {/* Toggle Button for Ads */}
          <div className="adsToggle">
            <span>Ads:</span>
            <Switch
              checked={adsEnabled}
              onChange={handleToggle}
              className={`${adsEnabled ? "bg-green-500" : "bg-gray-400"} relative inline-flex items-center h-6 rounded-full w-11`}
            >
              <span className="sr-only">Enable Ads</span>
              <span
                className={`${adsEnabled ? "translate-x-6" : "translate-x-1"} inline-block w-4 h-4 transform bg-white rounded-full`}
              />
            </Switch>
          </div>

          <div className="userProfile">
            <div
              className="userImage"
              onClick={() => setProfileMenu(!ProfileMenu)}
            >
              <img
                src={"/assets/image/avatar_default.jpg"}
                alt="User Profile Pic"
              />
            </div>
            <motion.div
              className="userProfileDropdown"
              initial={{ y: 40, opacity: 0, pointerEvents: "none" }}
              animate={{
                y: !ProfileMenu ? -30 : [0, 30, 10],
                opacity: ProfileMenu ? 1 : 0,
                pointerEvents: ProfileMenu ? "auto" : "none",
                zIndex: 999999,
              }}
              transition={{ duration: 0.48 }}
            >
              <div className="profileWrapper">
                <img
                  src={"/assets/image/avatar_default.jpg"}
                  alt="User Profile Pic"
                />
                <div className="profileData">
                  <div className="name">John Doe</div>
                  <span className="seeProfile">See Profile</span>
                </div>
              </div>
              <div className="linksWrapper">
                <div className="link">
                  <div className="leftSide">
                    <span className="icon">
                      <MdSettings />
                    </span>
                    <span className="name">Settings & Privacy</span>
                  </div>
                  <span className="actionIcon">
                    <FaAngleRight />
                  </span>
                </div>
                <div className="link">
                  <div className="leftSide">
                    <span className="icon">
                      <RiQuestionFill />
                    </span>
                    <span className="name">Help & Support</span>
                  </div>
                  <span className="actionIcon">
                    <FaAngleRight />
                  </span>
                </div>
              </div>
            </motion.div>
          </div>
        </div>
      </div>

      <motion.div
        className="mobileSearchPanel"
        initial={{ y: "100vh", pointerEvents: "none", display: "none" }}
        animate={{
          display: searchPanel ? "block" : "none",
          y: searchPanel ? 0 : "100vh",
          pointerEvents: searchPanel ? "auto" : "none",
          transition: {
            bounce: 0.23,
            type: "spring",
          },
        }}
      >
        <div className="closeBtn" onClick={() => setSearchPanel(false)}>
          <FaAngleDown />
        </div>

        <div className="inMobileSearch">
          <div className="mobileSearchIcon">
            <MdSearch className="inIcon" />
          </div>
          <input
            type="text"
            placeholder="Search"
            value={searchValue}
            onKeyUp={(e) => searchUsers(e.target.value)}
            onChange={(e) => setSearchValue(e.target.value)}
          />
          {searchValue.length >= 1 && (
            <MdClose
              className="inIcon cursor-pointer"
              onClick={() => {
                setSearchValue("");
                setTimeout(() => {
                  setSearchedUser(userData);
                }, 300);
              }}
            />
          )}
        </div>

        <motion.div
          className="searchResult"
          initial={{ y: 30, opacity: 0, pointerEvents: "none" }}
          animate={{
            y: searchValue.length >= 1 ? 0 : 30,
            opacity: searchValue.length >= 1 ? 1 : 0,
            pointerEvents: searchValue.length >= 1 ? "auto" : "none",
          }}
        >
          {searchedUser.length > 0 &&
            searchedUser.map((user, index) => {
              if (user.error) {
                return (
                  <div className="noUserFound" key={index}>
                    <FaFaceFrown />
                    <h3>Sorry {user.error}</h3>
                  </div>
                );
              } else {
                return (
                  <div key={index} className="searchResultItem">
                    <div className="userImage">
                      <img src={`${user.profilePic}`} alt="" />
                    </div>
                    <h3>{user.name}</h3>
                  </div>
                );
              }
            })}
        </motion.div>
      </motion.div>
    </>
  );
};

export default Navbar;
