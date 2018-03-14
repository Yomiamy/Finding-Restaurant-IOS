//
//  RestaurantListViewController2.swift
//  Restaurant-Demo
//
//  Created by yomi on 2018/3/3.
//  Copyright © 2018年 yomi. All rights reserved.
//

import UIKit
import TagListView
import GooglePlaces
import GooglePlacePicker

class RestaurantListViewController2: UITableViewController, RestaurantListViewProtocol, UISearchResultsUpdating, TagListViewDelegate {
    
    private static let CELL_ID = "menu_cell"
    
    @IBOutlet weak var mTlvFilterRuleTagList: TagListView!
    @IBOutlet weak var mVFilterRuleListContainerView: UIView!
    
    private var mScNameSearchController:UISearchController?
    private var mRcRefreshControl:UIRefreshControl?
    private var mLoadingAlertController:UIAlertController?
    private var mPresenter:RestaurantListPresenterProtocol?
    private var mRestaurantSummaryInfos: [YelpRestaruantSummaryInfo]?
    var mFilterConfig:FilterConfigs?
    
    // MARK:- Lif cycle & initialization
    override func viewDidLoad() {
        super.viewDidLoad()
        initView()
        
        self.mRestaurantSummaryInfos = Array<YelpRestaruantSummaryInfo>()
        self.mPresenter = RestaurantListPresenter()
        self.mPresenter?.attachView(view: self)
        self.mPresenter?.onViewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.mPresenter?.onViewDidAppear()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func initView() {
        /* Init NavigationController  */
        self.navigationController?.navigationBar.prefersLargeTitles = true
        
        /* Init TableView  */
        self.mRcRefreshControl = UIRefreshControl()
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 30
        if #available(iOS 10.0, *) {
            self.tableView.refreshControl = self.mRcRefreshControl
        } else {
            self.tableView.addSubview(self.mRcRefreshControl!)
        }
        self.mRcRefreshControl?.addTarget(self, action: #selector(refreshListToDefaultConfigs), for:.valueChanged)
        self.mRcRefreshControl?.attributedTitle = NSAttributedString(string: NSLocalizedString("Loading Data...", comment: ""))
        
        /* Init tag list view */
        self.mTlvFilterRuleTagList.textFont = UIFont.systemFont(ofSize: 16)
        
        /* Init SearchController */
        self.mScNameSearchController = UISearchController(searchResultsController: nil)
        // Don't hide nav bar during searching
        self.mScNameSearchController?.hidesNavigationBarDuringPresentation = false
        // Don't darker the background color during searching
        self.mScNameSearchController?.dimsBackgroundDuringPresentation = false
        self.mScNameSearchController?.searchResultsUpdater = self
        self.mScNameSearchController?.definesPresentationContext = true
        self.mScNameSearchController?.searchBar.sizeToFit()
        self.mScNameSearchController?.searchBar.placeholder = "Please input the keyword..."
        self.navigationItem.searchController = self.mScNameSearchController
        // Hide the search bar when scrolling up, Default is true. if setup as false it will always display
        self.navigationItem.hidesSearchBarWhenScrolling = false
        self.mScNameSearchController?.searchBar.searchBarStyle = .prominent
        
        /* Init float button */
        let floaty = Floaty()
        floaty.buttonImage =  #imageLiteral(resourceName: "menu_icon")
        floaty.openAnimationType = .pop
        floaty.hasShadow = false
        floaty.sticky = true
        floaty.paddingX = 20
        floaty.paddingY = 20
        floaty.itemTitleColor = UIColor.darkGray
        // Locate user's location
        floaty.addItem(icon:  #imageLiteral(resourceName: "location_icon")) { (floatItem) in
            self.mPresenter?.onLocationFloatItemClick()
        }
        floaty.addItem(icon:  #imageLiteral(resourceName: "filter")) { (floatItem) in
            self.mPresenter?.onFilterFloatItemClick()
        }
        self.view.addSubview(floaty)
    }
    
    // MARK: - Prepare Segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let identifier = segue.identifier;
        
        if identifier == "show_restaurant_detail" {
            let destViewController = segue.destination as! RestaurantDetailViewController
            let restaurantInfo = sender as! YelpRestaruantSummaryInfo
            
            destViewController.mRestaurantSummaryInfo = restaurantInfo
        }
    }
    
    // MARK: - Unwind Segue
    @IBAction func unwindToRestaurantList(segue: UIStoryboardSegue) {
        let segueIdentifier = segue.identifier
        
        if segueIdentifier == "press_apply_unwind_segue" {
            self.mPresenter?.onNewFilterConfigsApply(filterConfigs: self.mFilterConfig)
        }
    }
    
    // MARK: - UIRefreshController pull-to-refresh target
    @objc func refreshListToDefaultConfigs(_ sender: Any) {
        // Use the taipei station as default location
        self.mPresenter?.onEndRefreshToDefaultConfigs()
    }
    
    // MARK:- UISearchResultsUpdating
    func updateSearchResults(for searchController: UISearchController) {
        self.mPresenter?.onSearchKeyworkChange(keyword: searchController.searchBar.text)
    }
    
    // MARK:- TablViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.mRestaurantSummaryInfos?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: RestaurantListViewController2.CELL_ID, for: indexPath) as? RestaurantInfoTableViewCell else {
            fatalError("Cell is not of kind RestaurantInfoTableViewCell")
        }
        let restaurantInfo = self.mRestaurantSummaryInfos![indexPath.row]
        
        cell.mLbNameLabel.text = restaurantInfo.name
        cell.mLbDistanceLabel.text = String(format: "%.2fm", arguments: [restaurantInfo.distance!])
        cell.mLbPriceLabel.text = restaurantInfo.price ?? ""
        cell.mLbReviewsLabel.text = (restaurantInfo.review_count != nil) ? "\(restaurantInfo.review_count ?? 0) " + NSLocalizedString("Reviews", comment: "") : ""
        cell.mLbAddressLabel.text = restaurantInfo.location?.display_address?.joined()
        cell.mIvPhotoImageView.kf.setImage(with: URL(string: restaurantInfo.image_url ?? ""), placeholder:  #imageLiteral(resourceName: "no_image"))
        cell.mIvRatingImage.image = restaurantInfo.getRatingImage(rating: restaurantInfo.rating ?? 0.0)
        cell.mLbTypeLabel.text = restaurantInfo.categoriesStr
        
        return cell
    }
    
    // MARK: - Table view data delegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // TODO: It's workaround to avoid the crash when searchcontroller is activie and go back from detail page
        self.mScNameSearchController?.isActive = false
                
        self.mPresenter?.onRestaurantListItemSelect(summaryInfo: self.mRestaurantSummaryInfos?[indexPath.row])
    }
    
    // MARK:- RestaurantListViewProtocol
    func refreshList(restaurantSummaryInfos: [YelpRestaruantSummaryInfo]?) {
        self.mRestaurantSummaryInfos = restaurantSummaryInfos
        self.mRcRefreshControl?.endRefreshing()
        self.tableView.reloadData()
    }
    
    func refreshFilterTagList(filterConfigs: FilterConfigs?) {
        self.mTlvFilterRuleTagList.removeAllTags()
        if let sortRuleStr = filterConfigs?.mSortingRuleDisplayStr {
            let tagView = self.mTlvFilterRuleTagList.addTag(sortRuleStr)
            tagView.onTap = {
                tagView in
                guard self.mTlvFilterRuleTagList.tagViews.count > 1 else {
                    return
                }
                self.mTlvFilterRuleTagList.removeTagView(tagView)
                self.mPresenter?.onFilterTagTap(tagType: TagType.sorting_rule)
            }
        }
        if let openAt = filterConfigs?.mOpenAt {
            let openDate = Date(timeIntervalSince1970: Double(openAt))
            let formatter = DateFormatter()
            formatter.timeZone = TimeZone.current
            formatter.dateFormat = "yyyy-MM-dd HH:mm"
            let tagView = self.mTlvFilterRuleTagList.addTag(NSLocalizedString("OPEN AT ", comment: "") + formatter.string(from: openDate))
            tagView.onTap = {
                tagView in
                guard self.mTlvFilterRuleTagList.tagViews.count > 1 else {
                    return
                }
                self.mTlvFilterRuleTagList.removeTagView(tagView)
                self.mPresenter?.onFilterTagTap(tagType: TagType.open_at)
            }
        }
        if let priceStr = filterConfigs?.mPriceDisplayStr {
            let tagView = self.mTlvFilterRuleTagList.addTag(priceStr)
            tagView.onTap = {
                tagView in
                guard self.mTlvFilterRuleTagList.tagViews.count > 1 else {
                    return
                }
                self.mTlvFilterRuleTagList.removeTagView(tagView)
                self.mPresenter?.onFilterTagTap(tagType: TagType.price)
            }
        }
    }
    
    func showLoading(loadingContent:String) {
        self.mLoadingAlertController = UIAlertController(title: nil, message: loadingContent, preferredStyle: .alert)
        self.mLoadingAlertController?.view.tintColor = UIColor.black
        let loadingIndicator: UIActivityIndicatorView = UIActivityIndicatorView(frame: CGRect(x:10,y:5, width:50, height:50))
        
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.gray
        loadingIndicator.startAnimating();
        self.mLoadingAlertController?.view.addSubview(loadingIndicator)
        self.present(self.mLoadingAlertController!, animated: true, completion: nil)
    }
    
    func closeLoading() {
        if self.mLoadingAlertController != nil {
            self.dismiss(animated: true, completion: nil)
            self.mLoadingAlertController = nil
        }
    }
    
    func showAlertDialog(title: String, content: String, handler: ((UIAlertAction) -> Void)?) {
        let alertDialog = UIAlertController(title: title, message: content, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler:handler)
        alertDialog.addAction(okAction)
        self.present(alertDialog, animated: true, completion: nil)
    }
    
    func doPresent(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Swift.Void)?) {
        self.present(viewControllerToPresent, animated: flag, completion: completion)
    }
    func doDismiss(animated flag: Bool, completion: (() -> Swift.Void)?) {
        self.dismiss(animated: flag, completion: completion)
    }
    
    func doPerformSegue(withIdentifier identifier: String, sender: Any?) {
        self.performSegue(withIdentifier: identifier, sender: sender)
    }
}
